# ClassyFlux

[![License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/kzlekk/ClassyFlux/raw/master/LICENSE)
[![Language](https://img.shields.io/badge/swift-5.0-orange.svg)](https://swift.org/blog/swift-5-released/)
[![Build Status](https://travis-ci.com/kzlekk/ClassyFlux.svg?branch=master)](https://travis-ci.com/kzlekk/ClassyFlux)
[![Coverage Status](https://coveralls.io/repos/github/kzlekk/ClassyFlux/badge.svg?branch=master)](https://coveralls.io/github/kzlekk/ClassyFlux?branch=master)

Simple yet fully-featured Flux pattern implemented in Swift

## Brief Documentation

You can read more about Flux pattern [here](https://facebook.github.io/flux/docs/in-depth-overview/)

### FluxAction

FluxAction usually a plain object that carries information describing the context of particular user action or system event. Actions dispatched via FluxDispatcher implementation and broadcasted to all the workers registered in the dispatcher. FluxStore could modify its state in response to actions. FluxMiddleware could start asynchronous work and report back by broadcasting another actions.  

Example declaration:

```swift
enum Action {
    struct UpdateName: FluxAction {
        let name: String
    }
}
```
Example of sending the action with the default dispatcher on the main thread:

```swift
Action.UpdateName(name: "Great Name").dispatch()
```

### FluxDispatcher

FluxDispatcher dispatches an actions to the mix of workers, which could be stores, middlewares or even other dispatchers.  Actions dispatched from one worker to another and can be modified and/or replaced by the workers. Be careful of the order of the workers, it is important and can cause behavioural artefacts if not configured correctly.  

Usage example:

```swift
let dispatcher = FluxDispatcher() 

dispatcher.register(workers: [SomeStore(), SomeMiddleware(dispatcher: dispatcher), AnalyticsLogger()])

SomeAction(value: Value()).dispatch(with: dispatcher)
```

### FluxStore

FluxStore is a container that manages the underlaying state, broadcasts notifications about state changes. FluxStore is ObservableObject and can be used directly in SwiftUI view to render a state. State can be modified by sending relevant action to the dispatcher, where FluxStore instance is registered. FluxStore syncs state changes on main queue.

Example declaration:

```swift
class SomeStore: FluxStore<SomeState> {

    init() {
        super.init(initialState: SomeState())

        registerReducer(for: SomeAction.self) { (state, action) in
            state.value = action.value
            return [\SomeState.value] // Reports which part of the state did change
        }
    }
}
```

### FluxMiddleware

FluxMiddleware is intended to be used to run asynchronous work and update other components by sending appropriate actions to the dispatcher. 

Example declaration:

```swift
class SomeMiddleware: FluxMiddleware {

    private weak var dispatcher: FluxDispatcher?
    
    init(dispatcher: FluxDispatcher) {
        self.dispatcher = dispatcher
        
        super.init()

        registerHandler(for: SomeAction.self) { [unowned self] (action) in
            self.performWork(value: action.value) // Start async work
            // Handler passes the same action to subsequent workers by default
        }
        
        registerComposer(for: OtherAction.self) { (action) in
            return .next(ThirdAction()) // Pass another action to subsequent workers
        }
        
        registerComposer(for: IgnoredAction.self) { (action) in
            return .stop() // Do not pass the action to subsequent workers
        }
    }
    
    private func performWork(value: Value) {
        RemoteAPI.sendRequest(value: value) { [weak self] in
            SomeOtherAction(outcome: $0).dispatch(with: self?.dispatcher)
        }
    }
}
```

## Author


Natan Zalkin natan.zalkin@me.com

## License


ClassyFlux is available under the MIT license. See the LICENSE file for more info.
