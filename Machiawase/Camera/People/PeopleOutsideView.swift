//
//  PeopleOutsideView.swift
//  Machiawase
//
//  Created by naru on 2017/03/04.
//  Copyright © 2017年 hazukit. All rights reserved.
//

import UIKit

class PeopleOutsideView: UIView {
 
    struct Constants {
        static let Padding: CGFloat = 4.0
        static let ViewSize: CGSize = CGSize(width: 160.0, height: 160.0)
        static let ArrowFont: UIFont = UIFont.systemFont(ofSize: 18.0)
        static let ArrowSize: CGSize = CGSize(width: 20.0, height: 20.0)
        static let NameFont: UIFont = UIFont.boldSystemFont(ofSize: 12.0)
    }
    
    enum Style {
        case upLeft
        case up(x: CGFloat)
        case upRight
        case right(y: CGFloat)
        case bottomRight
        case bottom(x: CGFloat)
        case bottomLeft
        case left(y: CGFloat)
        case disable
    }
 
    init() {
        let frame: CGRect = CGRect(origin: .zero, size: Constants.ViewSize)
        super.init(frame: frame)
        
        self.addSubview(self.arrowLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var style: Style = .disable {
        didSet {
            self.arrowLabel.transform = self.arrowRotationTransform(for: self.style)
            self.arrowLabel.center = self.arrowCenterPoint(for: self.style)
            self.isHidden = self.arrowIsHidden(for: self.style)
        }
    }
    
    func arrawStyle(for location: PeopleLocation) -> Style {
        
        let thresholdX: CGFloat = UIScreen.main.bounds.width/2.0
        let thresholdY: CGFloat = UIScreen.main.bounds.height/2.0
        
        // up
        if location.y > thresholdY {
            if location.x < -thresholdX {
                return .upLeft
            } else if location.x > thresholdX {
                return .upRight
            } else {
                return .up(x: location.x)
            }
        }
        // bottom
        if location.y < -thresholdY {
            if location.x < -thresholdX {
                return .bottomLeft
            } else if location.x > thresholdX {
                return .bottomRight
            } else {
                return .bottom(x: location.x)
            }
        }
        // left
        if location.x < -thresholdX {
            return .left(y: location.y)
        }
        // right
        if location.x > thresholdX {
            return .right(y: location.y)
        }
        return .disable
    }
    
    func arrowIsHidden(for style: Style) -> Bool {
        switch style {
        case .disable:
            return true
        default:
            return false
        }
    }
    
    private func arrowRotationTransform(for style: Style) -> CGAffineTransform {
        let angle: CGFloat
        switch style {
        case .upLeft:
            angle = CGFloat(M_PI)*(-3/4)
        case .up(_):
            angle = CGFloat(M_PI)*(-1/2)
        case .upRight:
            angle = CGFloat(M_PI)*(-1/4)
        case .right(_):
            angle = CGFloat(M_PI)*0
        case .bottomRight:
            angle = CGFloat(M_PI)*1/4
        case .bottom(_):
            angle = CGFloat(M_PI)*1/2
        case .bottomLeft:
            angle = CGFloat(M_PI)*3/4
        case .left(_):
            angle = CGFloat(M_PI)*1
        default:
            angle = 0.0
        }
        return CGAffineTransform(rotationAngle: angle)
    }
    
    private func arrowCenterPoint(for style: Style) -> CGPoint {
        let point: CGPoint
        switch style {
        case .upLeft:
            point = CGPoint(x: Constants.Padding + Constants.ArrowSize.width/2.0, y: Constants.Padding + Constants.ArrowSize.width/2.0)
        case .up(let x):
            point = CGPoint(x: UIScreen.main.bounds.width/2.0 + x, y: Constants.Padding + Constants.ArrowSize.width/2.0)
        case .upRight:
            point = CGPoint(x: UIScreen.main.bounds.width - Constants.ArrowSize.width/2.0 - Constants.Padding, y: Constants.Padding + Constants.ArrowSize.width/2.0)
        case .right(let y):
            point = CGPoint(x: UIScreen.main.bounds.width - Constants.ArrowSize.width/2.0 - Constants.Padding, y: UIScreen.main.bounds.height/2.0 - y)
        case .bottomRight:
            point = CGPoint(x: UIScreen.main.bounds.width - Constants.ArrowSize.width/2.0 - Constants.Padding, y: UIScreen.main.bounds.height - Constants.ArrowSize.height/2.0 - Constants.Padding)
        case .bottom(let x):
            point = CGPoint(x: UIScreen.main.bounds.width/2.0 + x, y: UIScreen.main.bounds.height - Constants.ArrowSize.height/2.0 - Constants.Padding)
        case .bottomLeft:
            point = CGPoint(x: Constants.Padding + Constants.ArrowSize.height/2.0, y: UIScreen.main.bounds.height - Constants.ArrowSize.height/2.0 - Constants.Padding)
        case .left(let y):
            point = CGPoint(x: Constants.Padding + Constants.ArrowSize.height/2.0, y: UIScreen.main.bounds.height/2.0 - y)
        default:
            point = .zero
        }
        return point
    }
    
    lazy var arrowLabel: UILabel = {
        let frame: CGRect = CGRect(origin: .zero, size: Constants.ArrowSize)
        let label: UILabel = UILabel(frame: frame)
        label.textAlignment = .center
        label.font = Constants.ArrowFont
        label.textColor = UIColor.white
        label.text = "▶︎"
        return label
    }()
    
}
