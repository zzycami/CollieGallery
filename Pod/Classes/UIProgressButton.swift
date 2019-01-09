//
//  UIProgressButton.swift
//  pixiv-client
//
//  Created by 周泽勇 on 2018/12/22.
//  Copyright © 2018 bravedefault. All rights reserved.
//

import UIKit

private let progressAnimationKey = "progressAnimation"

@IBDesignable
public class UIProgressButton: UIButton {
    public enum Status: Int {
        case normal
        case light
        case waiting
        case progress
        case pause
        case dark
        case finish
    }
    
    // MARK: public property
    @IBInspectable public var progressLineWidth: CGFloat = 1.5
    
    @IBInspectable public var indeterminate:Bool = false {
        didSet {
            if oldValue == indeterminate {
                return
            }
            if indeterminate {
                self.progressLayer.strokeStart = 0.1
                self.progressLayer.strokeEnd = 1.0
                self.progressLayer.lineWidth = 1
                self.progressView.layer.removeAnimation(forKey: progressAnimationKey)
                self.progressView.layer.add(self.progressAnimation, forKey: progressAnimationKey)
            }else {
                self.progressLayer.actions = ["strokeStart":NSNull(), "strokeEnd": NSNull()];
                self.progressLayer.strokeStart = 0.0;
                self.progressLayer.strokeEnd = 0.0;
                self.progressLayer.lineWidth = 3;
                self.progressView.layer.removeAllAnimations()
            }
        }
    }
    
    @IBInspectable public var showsText:Bool = true
    @IBInspectable public var lineWidth: CGFloat = 3.0
    @IBInspectable public var highlightColor: UIColor = UIColor(displayP3Red: 251/255.0, green: 61/255.0, blue: 70/255.0, alpha: 1)
    @IBInspectable public var highlightTextColor: UIColor = UIColor.white
    
    @IBInspectable public var radius:CGFloat = 25.0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    public override var tintColor: UIColor! {
        get {
            return super.tintColor
        }
        
        set {
            super.tintColor = newValue
            self.progressLayer.strokeColor = newValue.cgColor
            self.borderLayer.strokeColor = newValue.cgColor
            self.borderLayer.fillColor = newValue.cgColor
            self.centerLayer.strokeColor = newValue.cgColor
        }
    }
    public var status: Status = .normal {
        didSet {
            if oldValue == status {
                return
            }
            DispatchQueue.main.async {
                self.restartAnimation()
                self.progress = 0
                var path: UIBezierPath?
                if self.status == .normal || self.status == .finish {
                    path = self.borderNormalPath
                    self.titleLabel?.isHidden = false
                    self.centerLayer.isHidden = false
                    self.borderLayer.isHidden = false
                    self.borderLayer.fillColor = self.tintColor.cgColor
                    self.progressView.isHidden = true
                    self.setTitleColor(UIColor.white, for: .normal)
                }else if self.status == .progress || self.status == .waiting {
                    path = self.borderPath
                    self.borderLayer.strokeColor = self.tintColor.cgColor
                    self.borderLayer.fillColor = UIColor.clear.cgColor
                    self.borderLayer.lineWidth = self.lineWidth
                    self.centerLayer.strokeColor = self.tintColor.cgColor
                    self.centerLayer.fillColor = UIColor.clear.cgColor
                    self.titleLabel?.isHidden = true
                    self.centerLayer.isHidden = false
                    self.progressView.isHidden = false
                    self.backgroundColor = UIColor.clear
                }else if self.status == .pause {
                    path = self.borderPath
                    self.centerLayer.lineWidth = self.lineWidth
                    self.centerLayer.fillColor = UIColor.clear.cgColor
                    self.borderLayer.fillColor = UIColor.clear.cgColor
                    self.titleLabel?.isHidden = true
                    self.progressView.isHidden = true
                    self.backgroundColor = UIColor.clear
                }else if self.status == .dark {
                    self.centerLayer.isHidden = false;
                    self.layer.cornerRadius = 5;
                    self.titleLabel?.isHidden = false;
                    self.progressView.isHidden = true;
                    self.setTitleColor(UIColor.white, for: .normal)
                    self.titleLabel?.font = UIFont.systemFont(ofSize: 18);
                }else if self.status == .light {
                    path = self.borderPath
                    self.borderLayer.fillColor = UIColor.clear.cgColor
                    self.centerLayer.isHidden = false
                    self.borderLayer.isHidden = false
                    self.centerLayer.lineWidth = self.lineWidth
                    self.backgroundColor = UIColor.clear
                    self.progressView.isHidden = true;
                    self.titleLabel?.isHidden = true
                }
                let animation = CABasicAnimation(keyPath: "path")
                animation.delegate = self
                animation.toValue = path?.cgPath
                animation.duration = 0.2
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = false
                animation.setValue("borderAnimation", forKey: "animationFlag")
                self.borderAnimation = animation
                self.borderLayer.removeAllAnimations()
                self.borderLayer.add(self.borderAnimation, forKey: "path")
            }
        }
    }
    
    public var centerHidden: Bool = true {
        didSet {
            centerLayer.isHidden = centerHidden
        }
    }
    
    // MARK: private property
    private var progress: CGFloat = 0
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = tintColor.cgColor
        layer.lineWidth = 3
        layer.strokeStart = 0
        layer.strokeEnd = 0
        return layer
    }()
    
    private lazy var centerLayer: CAShapeLayer =  {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = tintColor.cgColor
        layer.lineWidth = 3
        layer.lineCap = CAShapeLayerLineCap.round
        layer.lineJoin = CAShapeLayerLineJoin.round
        layer.strokeStart = 0
        layer.strokeEnd = 1
        return layer
    }()
    
    private lazy var borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = tintColor.cgColor
        layer.strokeColor = tintColor.cgColor
        layer.lineWidth = 1.5 //self.lineWidth
        layer.strokeStart = 0
        layer.strokeEnd = 1
        return layer
    }()
    
    private var pausePath: UIBezierPath? {
        if (bounds.width == 0 || bounds.height == 0) {
            return nil;
        }
        let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        let pauseLineWidth = bounds.height/3
        let pauseIntervalWidth = pauseLineWidth - 2
        path.move(to: CGPoint(x: center.x - pauseIntervalWidth/2, y: center.y - pauseLineWidth/2))
        path.addLine(to: CGPoint(x: center.x - pauseIntervalWidth/2, y: center.y + pauseLineWidth/2))
        
        path.move(to: CGPoint(x: center.x + pauseIntervalWidth/2, y: center.y + pauseLineWidth/2))
        path.addLine(to: CGPoint(x: center.x + pauseIntervalWidth/2, y: center.y - pauseLineWidth/2))
        return path
    }
    
    private var downloadPath: UIBezierPath? {
        if (bounds.width == 0 || bounds.height == 0) {
            return nil;
        }
        let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        let width = bounds.width
        let height = bounds.height
        let path = UIBezierPath()
        path.lineWidth = lineWidth*2
        path.move(to: CGPoint(x: center.x, y: center.y - height/5))
        path.addLine(to: CGPoint(x: center.x, y: center.y + height/5))
        path.addLine(to: CGPoint(x: center.x - width/6, y: center.y + 2))
        path.move(to: CGPoint(x: center.x, y: center.y + height/5))
        path.addLine(to: CGPoint(x: center.x + width/6, y: center.y + 2))
        return path
    }
    
    private var continuePath: UIBezierPath? {
        if (bounds.width == 0 || bounds.height == 0) {
            return nil;
        }
        let center = CGPoint(x: bounds.width/2 + 1, y: bounds.height/2)
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        let pauseLineWidth = bounds.height/3
        let pauseIntervalWidth = pauseLineWidth - 2
        path.move(to: CGPoint(x: center.x - pauseIntervalWidth/2, y: center.y - pauseLineWidth/2))
        path.addLine(to: CGPoint(x: center.x + pauseIntervalWidth/2, y: center.y))
        path.addLine(to: CGPoint(x: center.x - pauseIntervalWidth/2, y: center.y + pauseLineWidth/2))
        path.close()
        return path
    }
    
    private var borderPath: UIBezierPath? {
        if (bounds.width == 0 || bounds.height == 0) {
            return nil;
        }
        let frame = getCircleFrame(0)
        let path = UIBezierPath(roundedRect: frame, cornerRadius: frame.width/2)
        path.lineCapStyle = CGLineCap.butt
        path.lineWidth = lineWidth
        return path
    }
    
    private var borderNormalPath: UIBezierPath? {
        if (bounds.width == 0 || bounds.height == 0) {
            return nil;
        }
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 4)
        path.lineCapStyle = CGLineCap.butt
        path.lineWidth = lineWidth
        return path
    }
    
    private var progressPath: UIBezierPath? {
        if (bounds.width == 0 || bounds.height == 0) {
            return nil;
        }
        
        let rect = getCircleFrame(progressLineWidth)
        let center = CGPoint(x: rect.width/2 + rect.origin.x, y: rect.height/2 + rect.origin.y)
        let path = UIBezierPath(arcCenter: center, radius: rect.width/2, startAngle: -CGFloat.pi/2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        path.lineCapStyle = CGLineCap.butt
        path.lineWidth = lineWidth
        return path
    }
    
    private var borderAnimation: CABasicAnimation = CABasicAnimation()
    
    private var progressAnimation: CABasicAnimation = {
        let animation = CABasicAnimation()
        animation.keyPath = "transform.rotation"
        animation.toValue = Double.pi
        animation.duration = 0.5
        animation.setValue(progressAnimationKey, forKey: "animationFlag")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = MAXFLOAT
        animation.isCumulative = true
        return animation
    }()
    
    private var centerAnimation: CABasicAnimation = CABasicAnimation()
    
    private lazy var progressView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: public method
    @objc public func restartAnimation() {
        if indeterminate {
            progressView.layer.removeAnimation(forKey: progressAnimationKey)
            progressView.layer.add(progressAnimation, forKey: progressAnimationKey)
        }
    }
    
    public func setProgress(_ progress: CGFloat, animated: Bool) {
        if self.indeterminate && progress > 0 {
            self.indeterminate = false
        }
        if self.progress >= 1.0 && progress >= 1.0 {
            self.progress = 1.0
            return
        }
        var _progress: CGFloat = progress
        if progress < 0.0 {
            _progress = 0.0
        }
        if progress > 1.0 {
            _progress = 1.0
        }
        
        if _progress > 0.0 {
            self.borderLayer.isHidden = false;
            self.progressLayer.actions = animated ? nil : ["strokeEnd": NSNull()];
            self.progressLayer.strokeEnd = progress;
        }
        self.progress = _progress
    }
    
    // MARK: life cycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initialize() {
        backgroundColor = UIColor.clear
        titleLabel?.font = UIFont.systemFont(ofSize: 12)
        addSubview(progressView)
        progressView.isUserInteractionEnabled = false
        self.layer.addSublayer(borderLayer)
        progressView.layer.addSublayer(progressLayer)
        layer.addSublayer(centerLayer)
        progressLayer.path = progressPath?.cgPath
        centerLayer.isHidden = false
        if let titleLabel = self.titleLabel {
            bringSubviewToFront(titleLabel)
        }
        titleLabel?.textAlignment = NSTextAlignment.center
        NotificationCenter.default.addObserver(self, selector: #selector(UIProgressButton.restartAnimation), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.progressView.frame = self.bounds
        self.centerLayer.frame = self.bounds
        self.borderLayer.frame = self.bounds
        var frame = getCircleFrame(progressLineWidth)
        frame.origin = CGPoint(x: progressLineWidth/2, y: progressLineWidth/2)
        progressLayer.frame = frame
        progressLayer.path = progressPath?.cgPath
        titleLabel?.frame = bounds
        
        if status == .normal || status == .finish {
            borderLayer.path = borderNormalPath?.cgPath
            titleLabel?.isHidden = false
            indeterminate = false
            progressView.isHidden = true
            centerLayer.isHidden = false
        }else if status == .pause {
            borderLayer.path = borderPath?.cgPath
            centerLayer.path = continuePath?.cgPath
            titleLabel?.isHidden = true
            borderLayer.isHidden = false
            centerLayer.isHidden = false
            indeterminate = false
            progressView.isHidden = true
            self.backgroundColor = UIColor.clear
        }else if status == .progress || status == .waiting {
            self.borderLayer.path = self.borderPath?.cgPath
            self.centerLayer.path = self.pausePath?.cgPath
            self.centerLayer.isHidden = false;
            self.titleLabel?.isHidden = true;
            self.backgroundColor = UIColor.clear
        }else if status == .dark {
            titleLabel?.isHidden = false
        }else if status == .light {
            self.centerLayer.path = self.downloadPath?.cgPath
            self.borderLayer.path = self.borderPath?.cgPath
            self.borderLayer.fillColor = UIColor.clear.cgColor
            self.centerLayer.isHidden = false;
            self.titleLabel?.isHidden = true;
            self.backgroundColor = UIColor.clear
        }
    }
    
    public override var isEnabled: Bool {
        didSet {
            if isEnabled {
                tintColor = tintColor.withAlphaComponent(1)
            }else {
                tintColor = tintColor.withAlphaComponent(0.5)
            }
        }
    }
    
    // MARK: private method
    public func getCircleFrame(_ offset: CGFloat) -> CGRect {
        if bounds.width > bounds.height {
            let rectWidth = bounds.height
            let rectX = (self.bounds.size.width - self.bounds.size.height)/2
            return CGRect(x: rectX, y: 0, width: rectWidth - offset, height: rectWidth - offset)
        }else {
            let rectWidth = self.bounds.size.width
            let rectY = (self.bounds.size.width - self.bounds.size.height)/2
            return CGRect(x: 0, y: rectY, width: rectWidth - offset, height: rectWidth - offset)
        }
    }
}

extension UIProgressButton: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let key = anim.value(forKey: "animationFlag") as? String else {
            return
        }
        if key == "borderAnimation" {
            var centerLayerPath: UIBezierPath?
            if status == .normal || status == .finish {
                borderLayer.path = borderNormalPath?.cgPath
                indeterminate = true
                centerLayer.isHidden = true
            }else if status == .progress {
                borderLayer.path = borderPath?.cgPath
                centerLayer.isHidden = false
                if progress == 0 {
                    indeterminate = true
                }
                centerLayerPath = self.pausePath
            }else if status == .waiting {
                self.borderLayer.path = self.borderPath?.cgPath
                self.centerLayer.isHidden = false
                self.borderLayer.isHidden = true
                self.borderLayer.lineWidth = 1
                self.indeterminate = true
                centerLayerPath = self.pausePath
            }else if status == .pause {
                self.borderLayer.path = self.borderPath?.cgPath
                self.indeterminate = false
                self.centerLayer.isHidden = false
                self.borderLayer.isHidden = false
                centerLayerPath = self.continuePath
            }else if status == .light {
                self.borderLayer.path = self.borderPath?.cgPath
                self.indeterminate = false
                self.centerLayer.isHidden = false
                self.borderLayer.isHidden = false
                centerLayerPath = self.downloadPath
            }
            self.centerLayer.path = centerLayerPath?.cgPath
        }
    }
}
