//
//  WWProgressView.swift
//  WWProgressView
//
//  Created by William.Weng on 2021/11/22.
//
/// [Swift packages: Resources and localization - WWDC20 - Videos - Apple Developer](https://developer.apple.com/videos/play/wwdc2020/10169/)

import UIKit

public protocol SliderDeleagte: AnyObject {
    
    typealias SliderInfomation = (text: String?, icon: UIImage?)
    
    /// 值改變的時候
    /// - Parameters:
    ///   - identifier: 辨識字
    ///   - currentValue: 目前的值
    ///   - maximumValue: 最大值
    ///   - isVertical: 水平 / 垂直
    /// - Returns: ProgressViewInfomation
    func valueChange(identifier: String, currentValue: CGFloat, maximumValue: CGFloat, isVertical: Bool) -> SliderInfomation
}

@IBDesignable open class WWSlider: UIView {
    
    public enum ProgressType {
        case continuous
        case segmented(_ count: UInt)
    }
    
    @IBInspectable public var isVertical: Bool = true
    @IBInspectable public var currentValue: CGFloat = 0
    @IBInspectable public var iconPosition: CGFloat = 0
    @IBInspectable public var cornerRadius: CGFloat = 0
    @IBInspectable public var borderWidth: CGFloat = 0
    @IBInspectable public var progressColor: UIColor = .gray
    @IBInspectable public var borderColor: UIColor = .gray
    @IBInspectable public var identifier: String = "ProgressView"

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var iconPositionConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var verticalView: UIView!
    @IBOutlet weak var verticalProgressView: UIView!
    @IBOutlet weak var verticalDisplayImageView: UIImageView!
    @IBOutlet weak var verticalConstraint: NSLayoutConstraint!

    @IBOutlet weak var horizontalView: UIView!
    @IBOutlet weak var horizontalProgressView: UIView!
    @IBOutlet weak var horizontalDisplayImageView: UIImageView!
    @IBOutlet weak var horizontalConstraint: NSLayoutConstraint!

    @IBOutlet var contentView: UIView!

    public weak var myDeleagte: SliderDeleagte?
    
    private var touchPoint: (start: CGPoint?, constant: CGFloat) = (nil, 0)
    private var progressType: ProgressType = .continuous

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initViewFromXib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViewFromXib()
    }
    
    override public func draw(_ rect: CGRect) { redrawOnStoryboard() }
    
    /// [IB Designables: Failed to render and update auto layout status](https://stackoverflow.com/questions/46723683/ib-designables-failed-to-render-and-update-auto-layout-status)
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        contentView?.prepareForInterfaceBuilder()
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { recordStartTouchPoint(touches, with: event) }
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateConstraint(touches, with: event, isVertical: isVertical) }
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { clean() }
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}

// MARK: - 公開的
extension WWSlider {
        
    /// 設定一些初始的文字及圖示
    /// - Parameters:
    ///   - id: 辨識字
    ///   - initValue: 上方的Label文字
    ///   - font: Label字型
    ///   - icon: 下方的圖示
    ///   - type: 滑動的模式 (連續顯示 / 一段一段顯示)
    ///   - isVertical: 水平 / 垂直
    public func configure(id: String, initValue: String?, font: UIFont? = .systemFont(ofSize: 36.0), icon: UIImage? = nil, type: ProgressType = .continuous) {
                
        identifier = id
        progressType = type
                
        displayLabel.font = font
        displayLabel.text = initValue
        
        verticalDisplayImageView.image = icon
        horizontalDisplayImageView.image = icon
    }
    
    /// 直接設定數值，當進度條用
    /// - Parameters:
    ///   - constant: CGFloat
    ///   - info: ProgressViewDeleagte.ProgressViewInfomation
    /// - Returns: CGFloat
    public func valueSetting(constant: CGFloat, info: SliderDeleagte.SliderInfomation) -> CGFloat {
        
        touchPoint.constant = constant
        
        constraintSetting(isVertical: isVertical, constant: touchPoint.constant, type: progressType)
        valueSetting(isVertical: isVertical, info: info)
        
        return touchPoint.constant
    }
}

// MARK: - 小工具
extension WWSlider {
    
    /// 讀取Nib畫面 => 加到View上面
    private func initViewFromXib() {
        
        let bundle = Bundle.module
        let name = String(describing: WWSlider.self)
        
        bundle.loadNibNamed(name, owner: self, options: nil)
        contentView.frame = bounds
        
        addSubview(contentView)
    }
    
    /// 初始化參數設定
    private func initSetting() {
        
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        
        touchPoint.constant = safeTouchPointConstant(currentValue, isVertical: isVertical)
        iconPositionConstraint.constant = iconPosition
        
        verticalView.isHidden = !isVertical
        horizontalView.isHidden = isVertical
        
        if (isVertical) {
            verticalProgressView.backgroundColor = progressColor
            verticalConstraint.constant = touchPoint.constant
        } else {
            horizontalProgressView.backgroundColor = progressColor
            horizontalConstraint.constant = touchPoint.constant
        }
    }
    
    /// 及時畫面重繪 => @IBDesignable
    private func redrawOnStoryboard() {

        initSetting()
        
        #if TARGET_INTERFACE_BUILDER
        #endif
    }
    
    /// 記錄點擊的起點位置
    /// - Parameters:
    ///   - touches: Set<UITouch>
    ///   - event: UIEvent?
    private func recordStartTouchPoint(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchPoint.start = touch.location(in: self)
    }
    
    /// 更新Constraint (range: min ~ max)
    /// - Parameters:
    ///   - touches: Set<UITouch>
    ///   - event: UIEvent?
    ///   - isVertical: 水平 / 垂直
    private func updateConstraint(_ touches: Set<UITouch>, with event: UIEvent?, isVertical: Bool) {
        
        guard let startTouchPoint = touchPoint.start,
              let endTouchPoint = touches.first?.location(in: self)
        else {
            return
        }
        
        touchPoint.start = endTouchPoint
        touchPoint.constant += isVertical ? (startTouchPoint.y - endTouchPoint.y) : (endTouchPoint.x - startTouchPoint.x)
        touchPoint.constant = safeTouchPointConstant(touchPoint.constant, isVertical: isVertical)
        
        constraintSetting(isVertical: isVertical, constant: touchPoint.constant, type: progressType)
    }
    
    /// 刻度設定
    /// - Parameters:
    ///   - isVertical: 水平 / 垂直
    ///   - constant: CGFloat
    ///   - type: ProgressType
    private func constraintSetting(isVertical: Bool, constant: CGFloat, type: ProgressType) {
        
        if (isVertical) {
            verticalConstraint.constant = safeConstraint(constant, progressType: type)
            valueChangeAction(verticalConstraint.constant, isVertical: isVertical)
        } else {
            horizontalConstraint.constant = safeConstraint(constant, progressType: type)
            valueChangeAction(horizontalConstraint.constant, isVertical: isVertical)
        }
    }
    
    /// 設定數值的安全大小範圍 (顯示的高度) => 0 ~ 最大高度 / 寬度
    /// - Parameter touchPointConstant: CGFloat
    /// - Returns: CGFloat
    private func safeConstraint(_ touchPointConstant: CGFloat, progressType: ProgressType) -> CGFloat {
                
        switch progressType {
        case .continuous: return safeTouchPointConstant(touchPointConstant, isVertical: isVertical)
        case .segmented(let count): return safeSegmentedConstraint(count, touchPointConstant: touchPointConstant, isVertical: isVertical)
        }
    }
    
    /// 設定數值的安全大小範圍 (記錄的高度) => 0 ~ 最大高度
    /// - Parameter touchPointConstant: CGFloat
    /// - Returns: CGFloat
    private func safeTouchPointConstant(_ touchPointConstant: CGFloat, isVertical: Bool) -> CGFloat {
        
        let maximumTouchPointConstant = maximumTouchPointConstantMaker(isVertical: isVertical)

        if (touchPointConstant > maximumTouchPointConstant) { return maximumTouchPointConstant }
        if (touchPointConstant < .zero) { return .zero }
        
        return touchPointConstant
    }
    
    /// 產生出分段的安全高度Constraint (一格一格的)
    /// - Returns: CGFloat?
    /// - Parameters:
    ///   - count: 正整數
    ///   - touchPointConstant: 真正的所點的高度
    ///   - isVertical: 水平 / 垂直
    private func safeSegmentedConstraint(_ count: UInt, touchPointConstant: CGFloat, isVertical: Bool) -> CGFloat {
        
        let maximumTouchPointConstant = maximumTouchPointConstantMaker(isVertical: isVertical)
        
        let index = Int(touchPointConstant * CGFloat(count) / maximumTouchPointConstant)
        let value = maximumTouchPointConstant * CGFloat(index) / CGFloat(count)
        
        return value
    }
    
    /// 數值改變時的反應 (文字 / 圖形)
    /// - Parameter value: CGFloat?
    private func valueChangeAction(_ value: CGFloat, isVertical: Bool) {
        
        guard let maximumValue = Optional.some(maximumTouchPointConstantMaker(isVertical: isVertical)),
              let info = myDeleagte?.valueChange(identifier: identifier, currentValue: value, maximumValue: maximumValue, isVertical: isVertical)
        else {
            return
        }
        
        valueSetting(isVertical: isVertical, info: info)
    }
    
    /// 設定相關文字及圖示
    /// - Parameters:
    ///   - isVertical: 水平 / 垂直
    ///   - info: ProgressViewInfomation
    private func valueSetting(isVertical: Bool, info: SliderDeleagte.SliderInfomation) {
        
        displayLabel.text = info.text
        
        if (isVertical) {
            verticalDisplayImageView.image = info.icon
        } else {
            horizontalDisplayImageView.image = info.icon
        }
    }
    
    /// 傳回最大的容許值 (最高 / 最寬)
    /// - Parameter isVertical: 水平 / 垂直
    private func maximumTouchPointConstantMaker(isVertical: Bool) -> CGFloat {
        let constant = isVertical ? contentView.frame.height : contentView.frame.width
        return constant
    }
    
    /// 清除/還原一些設定值
    private func clean() { touchPoint.start = nil }
}
