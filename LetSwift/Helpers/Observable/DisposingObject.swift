//
//  DisposingObject.swift
//  LetSwift
//
//  Created by Marcin Chojnacki, Kinga Wilczek, Michał Pyrka on 18.05.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

final class DisposingObject: Disposable {
    
    private var disposeClosure: () -> ()
    private var alreadyDisposed = false
    
    init(disposeClosure: @escaping () -> ()) {
        self.disposeClosure = disposeClosure
    }
    
    deinit {
        dispose()
    }
    
    func dispose() {
        if !alreadyDisposed {
            disposeClosure()
            alreadyDisposed = true
        }
    }
    
    func add(to disposeBag: DisposeBag) {
        disposeBag.addDisposable(disposable: self)
    }
}
