// For License please refer to LICENSE file in the root of Persei project

import Foundation
import UIKit
import QuartzCore

private var ContentOffsetContext = 0

private let DefaultContentHeight: CGFloat = 64

public class StickyHeaderView: UIView {
    // MARK: - Init
    func commonInit() {
        addSubview(backgroundImageView)
        addSubview(contentContainer)

        contentContainer.addSubview(shadowView)
        
        clipsToBounds = true
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }

    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 320, height: DefaultContentHeight))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // MARK: - View lifecycle
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if newSuperview == nil, let view = superview as? UIScrollView {
            view.removeObserver(self, forKeyPath: "contentOffset", context: &ContentOffsetContext)
            view.panGestureRecognizer.removeTarget(self, action: #selector(StickyHeaderView.handlePan(_:)))
            appliedInsets = UIEdgeInsetsZero
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let view = superview as? UIScrollView {
            view.addObserver(self, forKeyPath: "contentOffset", options: [.initial, .new], context: &ContentOffsetContext)
            view.panGestureRecognizer.addTarget(self, action: #selector(StickyHeaderView.handlePan(_:)))
            view.sendSubview(toBack: self)
        }
    }

    private let contentContainer: UIView = {
        let view = UIView()
        view.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        view.backgroundColor = UIColor.clear()

        return view
    }()
    
    private let shadowView = HeaderShadowView(frame: CGRect.zero)
    
    @IBOutlet
    public var contentView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = contentView {
                view.frame = contentContainer.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                contentContainer.addSubview(view)
                contentContainer.sendSubview(toBack: view)
            }
        }
    }
    
    public enum ContentViewGravity {
        case top, center, bottom
    }
    
    /**
    Affects on `contentView` sticking position during view stretching: 
    
    - Top: `contentView` sticked to the top position of the view
    - Center: `contentView` is aligned to the middle of the streched view
    - Bottom: `contentView` sticked to the bottom
    
    Default value is `Center`
    **/
    public var contentViewGravity: ContentViewGravity = .center
    
    // MARK: - Background Image
    private let backgroundImageView = UIImageView()

    @IBInspectable
    public var backgroundImage: UIImage? {
        didSet {
            backgroundImageView.image = backgroundImage
            backgroundImageView.isHidden = backgroundImage == nil
        }
    }
    
    // MARK: - ScrollView
    private var scrollView: UIScrollView! { return superview as! UIScrollView }
    
    // MARK: - KVO
    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        if context == &ContentOffsetContext {
            didScroll()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - State
    public var revealed: Bool = false {
        didSet {
            if oldValue != revealed {
                if revealed {
                    self.addInsets()
                } else {
                    self.removeInsets()
                }
            }
        }
    }
    
    private func setRevealed(_ revealed: Bool, animated: Bool, adjustContentOffset adjust: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                self.revealed = revealed
            }, completion: { completed in
                if adjust {
                    UIView.animate(withDuration: 0.2) {
                        self.scrollView.contentOffset.y = -self.scrollView.contentInset.top
                    }
                }
            })
        } else {
            self.revealed = revealed
            
            if adjust {
                self.scrollView.contentOffset.y = -self.scrollView.contentInset.top
            }
        }
    }
    
    public func setRevealed(_ revealed: Bool, animated: Bool) {
        setRevealed(revealed, animated: animated, adjustContentOffset: true)
    }

    private func fractionRevealed() -> CGFloat {
        return min(bounds.height / contentHeight, 1)
    }

    // MARK: - Applyied Insets
    private var appliedInsets: UIEdgeInsets = UIEdgeInsetsZero
    private var insetsApplied: Bool {
        return appliedInsets != UIEdgeInsetsZero
    }

    private func applyInsets(_ insets: UIEdgeInsets) {
        let originalInset = scrollView.contentInset - appliedInsets
        let targetInset = originalInset + insets

        appliedInsets = insets
        scrollView.contentInset = targetInset
    }
    
    private func addInsets() {
        assert(!insetsApplied, "Internal inconsistency")
        applyInsets(UIEdgeInsets(top: contentHeight, left: 0, bottom: 0, right: 0))
    }

    private func removeInsets() {
        assert(insetsApplied, "Internal inconsistency")
        applyInsets(UIEdgeInsetsZero)
    }
    
    // MARK: - ContentHeight
    @IBInspectable
    public var contentHeight: CGFloat = DefaultContentHeight {
        didSet {
            if superview != nil {
                layoutToFit()
            }
        }
    }
    
    // MARK: - Threshold
    @IBInspectable
    public var threshold: CGFloat = 0.3
    
    // MARK: - Content Offset Hanlding
    private func applyContentContainerTransform(_ progress: CGFloat) {
        var transform = CATransform3DIdentity
        transform.m34 = -1 / 500
        let angle = (1 - progress) * CGFloat(M_PI_2)
        transform = CATransform3DRotate(transform, angle, 1, 0, 0)
        
        contentContainer.layer.transform = transform
    }
    
    private func didScroll() {
        layoutToFit()
        layoutIfNeeded()
        
        let progress = fractionRevealed()
        shadowView.alpha = 1 - progress

        applyContentContainerTransform(progress)
    }
    
    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .ended {
            let value = scrollView.normalizedContentOffset.y * (revealed ? 1 : -1)
            let triggeringValue = contentHeight * threshold
            let velocity = recognizer.velocity(in: scrollView).y
            
            if triggeringValue < value {
                let adjust = !revealed || velocity < 0 && -velocity < contentHeight
                setRevealed(!revealed, animated: true, adjustContentOffset: adjust)
            } else if 0 < bounds.height && bounds.height < contentHeight {
                UIView.animate(withDuration: 0.3) {
                    self.scrollView.contentOffset.y = -self.scrollView.contentInset.top
                }
            }
        }
    }
    
    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()

        backgroundImageView.frame = bounds
        
        let containerY: CGFloat
        switch contentViewGravity {
        case .top:
            containerY = min(bounds.height - contentHeight, bounds.minY)

        case .center:
            containerY = min(bounds.height - contentHeight, bounds.midY - contentHeight / 2)
            
        case .bottom:
            containerY = bounds.height - contentHeight
        }
        
        contentContainer.frame = CGRect(x: 0, y: containerY, width: bounds.width, height: contentHeight)
        // shadow should be visible outside of bounds during rotation
        shadowView.frame = contentContainer.bounds.insetBy(dx: -round(contentContainer.bounds.width / 16), dy: 0)
    }

    private func layoutToFit() {
        let origin = scrollView.contentOffset.y + scrollView.contentInset.top - appliedInsets.top
        frame.origin.y = origin
        
        sizeToFit()
    }
    
    public override func sizeThatFits(_: CGSize) -> CGSize {
        var height: CGFloat = 0
        if revealed {
            height = appliedInsets.top - scrollView.normalizedContentOffset.y
        } else {
            height = scrollView.normalizedContentOffset.y * -1
        }

        let output = CGSize(width: scrollView.bounds.width, height: max(height, 0))
        
        return output
    }
}
