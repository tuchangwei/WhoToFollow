//
//  HomeViewModel.swift
//  WhoToFollow
//
//  Created by Changwei Tu on 08/11/2016.
//  Copyright © 2016 tuchangwei. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
struct HomeViewModel {
    
    var suggestion1Stream:Observable<User?>!
    var suggestion2Stream:Observable<User?>!
    var suggestion3Stream:Observable<User?>!
    
     init(input:(
        refreshClickStream: Observable<Void>,
        close1ClickStream: Observable<Void>,
        close2ClickStream: Observable<Void>,
        close3ClickStream: Observable<Void>
        )) {
        let startupRequestStream = Observable.just("https://api.github.com/users")
        //stream when click Refresh Button
        let requestOnRefreshStream:Observable<String> = input.refreshClickStream.map {
            let randomOffset = arc4random()%1000
            return "https://api.github.com/users?since=\(randomOffset)"
        }
        //as same as: requestStream = requestOnRefreshStream.startWith("https://api.github.com/users")
        let requestStream = Observable.of(startupRequestStream, requestOnRefreshStream).merge()
        let responseStream = requestStream
//            .do(onNext: { (_) in
//                UIApplication.shared.isNetworkActivityIndicatorVisible = true
//            })
            .flatMap({ urlStr -> Observable<[User]> in
            let url = URL(string: urlStr)!
            return URLSession.shared.rx.json(url: url)
                .do(onSubscribe: {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                })
                .observeOn(SerialDispatchQueueScheduler(qos: .background))
                .map({ json in
                    guard let json = json as? [AnyObject] else {
                        throw NSError(domain: "Parsing error", code: 0, userInfo: nil)
                    }
                    var users = [User]()
                    for obj in json {
                        if let dic = obj as? NSDictionary,
                            let name = dic["login"] as? String,
                            let avatar = dic["avatar_url"] as? String{
                            let user = User(name: name, avatar: avatar)
                            users.append(user)
                        }
                    }
                    return users
                })
                .observeOn(MainScheduler.instance)
                .do(onNext: { (_) in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                })
                .catchError({ _ in
                    return Observable.empty()
                })
        })
        suggestion1Stream = createSuggestionStream(refreshClickStreeam: input.refreshClickStream,
                                                   responseStream: responseStream,
                                                   closeClickStream: input.close1ClickStream)
        suggestion2Stream = createSuggestionStream(refreshClickStreeam: input.refreshClickStream,
                                                   responseStream: responseStream,
                                                   closeClickStream: input.close2ClickStream)
        suggestion3Stream = createSuggestionStream(refreshClickStreeam: input.refreshClickStream,
                                                   responseStream: responseStream,
                                                   closeClickStream: input.close3ClickStream)
        
    }
    
    fileprivate func createSuggestionStream(refreshClickStreeam: Observable<Void>,
                                            responseStream:Observable<[User]>,
                                            closeClickStream: Observable<Void>) -> Observable<User?> {
        //so when the refresh button clicked, the suggestion is cleared first.
        let part1:Observable<User?> = refreshClickStreeam.map{
            return nil
        }
        //The combineLatest() uses the most recent of the two sources,
        //but if one of those sources hasn't emitted anything yet,
        //combineLatest() cannot produce a data event on the output stream. 
        //If you look at the ASCII diagram above, 
        //you will see that the output has nothing when the first stream emitted value a. 
        //Only when the second stream emitted value b could it produce an output value.
        
        //There are different ways of solving this,
        //and we will stay with the simplest one, 
        //which is simulating a click to the 'close 1' button on startup:
        let part2:Observable<User?> =  Observable.combineLatest(closeClickStream.startWith(()), responseStream) { (Void, users) -> User in
            let randomIndex = Int(arc4random()%UInt32(users.count))
            return users[randomIndex]
        }
        let suggestionStream = Observable.of(part1,part2).merge().startWith(nil)
        return suggestionStream
    }
}
