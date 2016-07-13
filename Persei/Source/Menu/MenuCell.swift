// For License please refer to LICENSE file in the root of Persei project

import Foundation
import UIKit

class MenuCell: UICollectionViewCell {
    // MARK: - Init
    private func commonInit() {
        backgroundView = UIView()
        
        let views: [String: AnyObject] = ["imageView": imageView, "shadowView": shadowView]
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|-[imageView]-|",
                options: [],
                metrics: nil,
                views: views
            )
        )
        
        contentView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-[imageView]-|",
                options: [],
                metrics: nil,
                views: views
            )
        )
        
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowView)
        contentView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|[shadowView]|",
                options: [],
                metrics: nil,
                views: views
            )
        )
        contentView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:[shadowView(2)]|",
                options: [],
                metrics: nil,
                views: views
            )
        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        object = nil
    }
    
    // MARK: - ShadowView
    private let shadowView = UIView()
    
    // MARK: - ImageView
    private let imageView = UIImageView()
    
    // MARK: - Object
    var object: MenuItem? {
        didSet {
            imageView.image = object?.image
            imageView.highlightedImage = object?.highlightedImage
            shadowView.backgroundColor = object?.shadowColor
            
            updateSelectionVisibility()
        }
    }
    
    // MARK: - Selection
    private func updateSelectionVisibility() {
        imageView.isHighlighted = isSelected
        backgroundView?.backgroundColor = isSelected ? object?.highlightedBackgroundColor : object?.backgroundColor
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionVisibility()
        }
    }
}
