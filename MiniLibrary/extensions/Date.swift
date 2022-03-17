//
//  Date.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import Foundation

extension Date {
    
    func addDate(_ num:Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: num, to: self)!
    }
    
    func addHour(_ num:Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: num, to: self)!
    }
    
    func addMinute(_ num:Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: num, to: self)!
    }
    
    func string(format:String = "yyyy/M/dd") -> String {
        return DateUtils.stringFromDate(date: self, format: format)
    }
    
    func date() -> String {
        return DateUtils.stringFromDate(date: self, format: "M/d")
    }
    
    func difference(from:Date) -> Int {
        return Calendar(identifier: .gregorian).dateComponents([.day], from: from, to: self).day!
    }
    
    func differenceMinute(from:Date) -> Int {
        return Calendar(identifier: .gregorian).dateComponents([.minute], from: from, to: self).minute!
    }
    
    func differenceHour(from:Date) -> Int {
        return Calendar(identifier: .gregorian).dateComponents([.hour], from: from, to: self).hour!
    }
    
    func differenceNanosecond(from:Date) -> Int {
        return Calendar(identifier: .gregorian).dateComponents([.nanosecond], from: from, to: self).nanosecond ?? 0
    }
    
    func differenceSecond(from:Date) -> Int {
        return Calendar(identifier: .gregorian).dateComponents([.second], from: from, to: self).second ?? 0
    }
    
}
