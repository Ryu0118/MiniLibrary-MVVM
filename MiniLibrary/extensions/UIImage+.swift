//
//  UIImage+.swift
//  MiniLibrary
//
//  Created by Ryu on 2022/03/17.
//

import UIKit


extension CGRect {

    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    var center: CGPoint {
        get { return CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }
    var centerX: CGFloat {
        get { return midX }
        set { origin.x = newValue - width * 0.5 }
    }
    var centerY: CGFloat {
        get { return midY }
        set { origin.y = newValue - height * 0.5 }
    }
    
}

extension CGSize {
    mutating func convert() {
        self = CGSize(width: self.height, height: self.width)
    }
}


extension UIImage {
    
    static var noimage: UIImage {
        return UIImage(named: "noimage")!
    }
    
    func cropping(to: CGSize) -> UIImage? {
        
        let rect = CGRect(center: CGPoint(x: self.size.width/2, y: self.size.height/2), size: to)
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                break
            }
        }

        UIGraphicsBeginImageContextWithOptions(rect.size, opaque, scale)
        draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func rotatedBy(degree: CGFloat) -> UIImage {
        let radian = -degree * CGFloat.pi / 180
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: self.size.width / 2, y: self.size.height / 2)
        context.scaleBy(x: 1.0, y: -1.0)

        context.rotate(by: radian)
        context.draw(self.cgImage!, in: CGRect(x: -(self.size.width / 2), y: -(self.size.height / 2), width: self.size.width, height: self.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rotatedImage
    }
    
    func correctOrientation(size:inout CGSize) -> UIImage {
        switch self.imageOrientation {
        case .down:
            let offset:CGFloat = -90
            size.convert()
            return self.rotatedBy(degree: offset)
        case .up:
            let offset:CGFloat = 90
            size.convert()
            return self.rotatedBy(degree: offset)
        case .left:
            let offset:CGFloat = 180
            return self.rotatedBy(degree: offset)
        case .right:
            return self
        default:
            return self
        }
    }

    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

}
