//
//  CollieGalleryDelegate.swift
//  Pods
//
//  Created by Guilherme Munhoz on 5/11/16.
//
//

import UIKit

/// Protocol to implement the gallery
@objc public protocol CollieGalleryDelegate: class {
    
    /// Called when the gallery index changes
    @objc optional func gallery(_ gallery: CollieGallery, indexChangedTo index: Int)
    
    @objc optional func galleryDidDismiss(_ gallery: CollieGallery)
    
    @objc optional func galleryStartDownload(_ gallery: CollieGallery, picture: CollieGalleryPicture, pictureViews: CollieGalleryView, downloadButton: UIProgressButton)
    
}
