//
//  CollieGalleryView.swift
//
//  Copyright (c) 2016 Guilherme Munhoz <g.araujo.munhoz@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import Kingfisher

internal class CollieGalleryView: UIView, UIScrollViewDelegate {
    
    // MARK: - Internal properties
    var delegate: CollieGalleryViewDelegate?
    var picture: CollieGalleryPicture!
    var scrollView: UIScrollView!
    var imageView: UIImageView!
    var activityIndicator: UCZProgressView!
    var isZoomed: Bool {
        get {
            return scrollView.zoomScale > scrollView.minimumZoomScale
        }
    }
    
    // MARK: - Private properties
    fileprivate var options: CollieGalleryOptions!
    fileprivate var theme: CollieGalleryTheme!
    fileprivate var scrollFrame: CGRect {
        get {
            return CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        }
    }
    
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    convenience init(picture: CollieGalleryPicture, frame: CGRect,
                     options: CollieGalleryOptions, theme: CollieGalleryTheme)
    {
        self.init(frame: frame)
        
        self.picture = picture
        self.options = options
        self.theme = theme
        
        setupView()
        setupGestures()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Private functions
    fileprivate func setupView() {
        backgroundColor = UIColor.clear
        
        setupScrollView()
        setupImageView()
        setupActivityIndicatorView()
    }

    fileprivate func setupScrollView() {
        scrollView = UIScrollView(frame: scrollFrame)
        scrollView.delegate = self
        scrollView.contentSize = frame.size
        scrollView.bounces = false
        scrollView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = options.maximumZoomScale
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        scrollView.backgroundColor = UIColor.clear
        isUserInteractionEnabled = options.enableZoom
        
        addSubview(scrollView)
    }
    
    fileprivate func setupImageView() {
        imageView = UIImageView(frame: scrollFrame)
        imageView.contentMode = UIView.ContentMode.scaleToFill
        imageView.backgroundColor = UIColor.clear
        
        scrollView.addSubview(imageView)
    }
    
    fileprivate func setupActivityIndicatorView() {
        activityIndicator = UCZProgressView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        activityIndicator.frame = imageView.bounds
        activityIndicator.showsText = true
        activityIndicator.indeterminate = true
        activityIndicator.blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        if #available(iOS 10, *) {
            activityIndicator.usesVibrancyEffect = false
        }else {
            activityIndicator.usesVibrancyEffect = true
        }
        activityIndicator.lineWidth = 1
        activityIndicator.radius = 20
        activityIndicator.textSize = 12
        activityIndicator.alpha = 0.9
        
        addSubview(activityIndicator)
    }

    fileprivate func setupGestures() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(CollieGalleryView.viewTapped(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(tapRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(CollieGalleryView.viewDoubleTapped(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(CollieGalleryView.viewPressed(_:)))
        longPressRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(longPressRecognizer)
        
        tapRecognizer.require(toFail: doubleTapRecognizer)
    }
    
    fileprivate func zoomToScale(_ newZoomScale: CGFloat, pointInView: CGPoint) {
        let scrollViewSize = bounds.size
        
        let width = scrollViewSize.width / newZoomScale
        let height = scrollViewSize.height / newZoomScale
        
        let x = pointInView.x - (width / 2.0)
        let y = pointInView.y - (height / 2.0)
        
        let rectToZoomTo = CGRect(x: x, y: y, width: width, height: height);
        
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }

    fileprivate func centerImageViewToSuperView() {
        var zoomFrame = imageView.frame
        
        if(zoomFrame.size.width < scrollView.bounds.size.width) {
            zoomFrame.origin.x = (scrollView.bounds.size.width - zoomFrame.size.width) / 2.0
            
        } else {
            zoomFrame.origin.x = 0.0
            
        }
        
        if(zoomFrame.size.height < scrollView.bounds.size.height) {
            zoomFrame.origin.y = (scrollView.bounds.size.height - zoomFrame.size.height) / 2.0
            
        } else {
            zoomFrame.origin.y = 0.0
            
        }
        
        imageView.frame = zoomFrame
        
    }
    
    fileprivate func updateImageViewSize() {
        if let image = imageView.image {
            var imageSize = CGSize(width: image.size.width / image.scale, height: image.size.height / image.scale)
            
            let widthRatio = imageSize.width / bounds.size.width
            let heightRatio = imageSize.height / bounds.size.height
            let imageScaleRatio = max(widthRatio, heightRatio)
            
            imageSize = CGSize(width: imageSize.width / imageScaleRatio, height: imageSize.height / imageScaleRatio)
            
            imageView.frame = CGRect(x: 0.0, y: 0.0, width: imageSize.width, height: imageSize.height)
            
            restoreZoom(false)
            centerImageViewToSuperView()
        }
    }
    
    
    // MARK: - Internal functions
    func zoomToPoint(_ pointInView: CGPoint) {
        var newZoomScale = scrollView.minimumZoomScale
        
        if scrollView.zoomScale < (scrollView.maximumZoomScale / 2) {
            newZoomScale = options.maximumZoomScale
        }
        
        zoomToScale(newZoomScale, pointInView: pointInView)
    }

    func restoreZoom(_ animated: Bool = true) {
        if animated {
            zoomToScale(scrollView.minimumZoomScale, pointInView: CGPoint.zero)
        } else {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }
    
    func loadImage() {
        if self.imageView.image == nil {
            //If large image exist
            var image = self.picture.largeImage
            let imageCache =  KingfisherManager.shared.cache
            
            if image == nil {
                if let url = self.picture.largeUrl {
                    image = imageCache.retrieveImageInMemoryCache(forKey:url)
                    if image == nil {
                        image = imageCache.retrieveImageInDiskCache(forKey:url)
                    }
                }
            }
            if image != nil {
                self.imageView.image = image
                self.updateImageViewSize()
                self.activityIndicator.removeFromSuperview()
            }else {
                if let image = self.picture.image {
                    self.imageView.image = image
                    self.updateImageViewSize()
                    self.activityIndicator.removeFromSuperview()
                } else if let url = self.picture.url {
                    if let placeholder = self.picture.placeholder {
                        self.imageView.image = placeholder
                        self.updateImageViewSize()
                    }
                    
                    self.imageView.kf.setImage(with: URL(string:url)!, placeholder: self.picture.placeholder, options: [.requestModifier(self.picture)], progressBlock: {[weak self](receivedSize, totalSize)  in
                        let progress = CGFloat(receivedSize)/CGFloat(totalSize)
                        self?.activityIndicator.progress = progress
                    }) {[weak self] (image, error, cacheType, imageURL) in
                        if image != nil {
                            self?.imageView.image = image
                            self?.updateImageViewSize()
                            self?.activityIndicator.progress = 1
                            self?.activityIndicator.progressAnimiationDidStop({
                                self?.activityIndicator.removeFromSuperview()
                            })
                        }
                    }
                }
            }
        }
    }
    
    func loadLargeImage()  {
        if let image = self.picture.largeImage {
            self.imageView.image = image
            self.updateImageViewSize()
        } else if let url = self.picture.largeUrl {
            if let activityIndicator = self.activityIndicator {
                if !self.subviews.contains(activityIndicator) {
                    self.addSubview(activityIndicator)
                }
            }
            
            var placeholderImage:UIImage?
            let imageCache = KingfisherManager.shared.cache
            if let placeholderUrl = self.picture.url {
                placeholderImage = imageCache.retrieveImageInMemoryCache(forKey:placeholderUrl)
                if placeholderImage == nil {
                    placeholderImage = imageCache.retrieveImageInDiskCache(forKey:placeholderUrl)
                }
            }
            
            self.imageView.kf.setImage(with: URL(string:url)!, placeholder: placeholderImage, options: [.requestModifier(self.picture)], progressBlock: {[weak self](receivedSize, totalSize)  in
                let progress = CGFloat(receivedSize)/CGFloat(totalSize)
                self?.activityIndicator.progress = progress
            }) {[weak self] (image, error, cacheType, imageURL) in
                if image != nil {
                    self?.imageView.image = image
                    self?.updateImageViewSize()
                    self?.activityIndicator.progress = 1
                    self?.activityIndicator.progressAnimiationDidStop({
                        self?.activityIndicator.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    func clearImage() {
        imageView.image = nil
    }

    
    // MARK: - UIView methods
    override func layoutSubviews() {
        scrollView.frame = scrollFrame
        scrollView.contentSize = scrollView.frame.size
        scrollView.zoomScale = scrollView.minimumZoomScale
        updateImageViewSize()
    }
    
    
    // MARK: - UIGestureRecognizer handlers
    @objc func viewPressed(_ recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizer.State.began) {
            if let delegate = delegate {
                delegate.galleryViewPressed(self)
            }
        }
    }
    
    @objc func viewTapped(_ recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            restoreZoom()
            
        }
        
        if let delegate = delegate {
            delegate.galleryViewTapped(self)
        }
    }

    @objc func viewDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        zoomToPoint(pointInView)
    }
    
    
    //  MARK: - UIScrollView delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if (scrollView.zoomScale > scrollView.maximumZoomScale) {
            scrollView.zoomScale = scrollView.maximumZoomScale
        }

        centerImageViewToSuperView()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if let delegate = delegate {
            if scrollView.zoomScale == scrollView.minimumZoomScale {
                delegate.galleryViewDidRestoreZoom(self)
                
            } else {
                delegate.galleryViewDidZoomIn(self)
                
            }
        }
        
        let oldState = scrollView.isScrollEnabled
        
        scrollView.isScrollEnabled = (scrollView.zoomScale > scrollView.minimumZoomScale)
        
        if let delegate = delegate , scrollView.isScrollEnabled != oldState {
            if scrollView.isScrollEnabled {
                delegate.galleryViewDidEnableScroll(self)
            } else {
                delegate.galleryViewDidDisableScroll(self)
            }
        }
    }
}
