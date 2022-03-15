//
//  Reactive+.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/15.
//

import RxSwift
import RxCocoa

extension Reactive where Base: UIControl {
    func controlEvents(_ events:[UIControl.Event]) -> Observable<()> {
        return ControlEvent<()>.merge(events.map { event -> Observable<()> in
            return controlEvent(event).asObservable()
        })
    }
}
