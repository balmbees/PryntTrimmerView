//
//  PryntTrimmerView.swift
//  PryntTrimmerView
//
//  Created by HHK on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: class {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

/// A view to select a specific time range of a video. It consists of an asset preview with thumbnails inside a scroll view, two
/// handles on the side to select the beginning and the end of the range, and a position bar to synchronize the control with a
/// video preview, typically with an `AVPlayer`.
/// Load the video by setting the `asset` property. Access the `startTime` and `endTime` of the view to get the selected time
// range
@IBDesignable public class TrimmerView: AVAssetTimeSelector {

    // MARK: - Properties

    // MARK: Color Customization

    /// The color of the main border of the view
    @IBInspectable public var mainColor: UIColor = UIColor.orange {
        didSet {
            updateMainColor()
        }
    }

    /// The color of the handles on the side of the view
    @IBInspectable public var handleColor: UIColor = UIColor.gray {
        didSet {
            updateHandleColor()
        }
    }

    /// The color of the position indicator
    @IBInspectable public var positionBarColor: UIColor = UIColor.white {
        didSet {
            positionBar.backgroundColor = positionBarColor
        }
    }

    /// The Image of the handles on the side of the view
    public var leftHandleImage: UIImage? {
        didSet {
            leftHandleKnob.image = leftHandleImage
        }
    }

    public var rightHandleImage: UIImage? {
        didSet {
            rightHandleKnob.image = rightHandleImage
        }
    }

    /// Seekbar handle when previous endTime is greater than current endTime
    public var isNaturalSeekbarControl: Bool = true
    private var sideConstraint: CGFloat?
    // MARK: Interface

    public weak var delegate: TrimmerViewDelegate?

    // MARK: Subviews

    private let trimView = UIView()
    private let leftHandleView = HandlerView()
    private let rightHandleView = HandlerView()
    private let positionBar = UIView()
    private let leftHandleKnob = UIImageView()
    private let rightHandleKnob = UIImageView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()

    // MARK: Constraints

    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?

    private let handleWidth: CGFloat = 15

    /// The maximum duration allowed for the trimming. Change it before setting the asset, as the asset preview
    public var maxDuration: Double = Double.greatestFiniteMagnitude

    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 1

    // MARK: - View & constraints configurations

    override func setupSubviews() {

        super.setupSubviews()
        backgroundColor = UIColor.clear
        layer.zPosition = 1
        setupTrimmerView()
        setupHandleView()
        setupMaskView()
        setupPositionBar()
        setupGestures()
        updateMainColor()
        updateHandleColor()
    }

    override func constrainAssetPreview() {
        assetPreview.leftAnchor.constraint(equalTo: leftAnchor, constant: handleWidth).isActive = true
        assetPreview.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth).isActive = true
        assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func setupTrimmerView() {

        trimView.layer.borderWidth = 2.0
        trimView.layer.cornerRadius = 2.0
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        addSubview(trimView)

        trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
        rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
    }

    private func setupHandleView() {

        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.layer.cornerRadius = 2.0
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftHandleView)

        leftHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.addSubview(leftHandleKnob)

        leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
        leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.layer.cornerRadius = 2.0
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightHandleView)

        rightHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.addSubview(rightHandleKnob)

        rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
        rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupMaskView() {

        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = .white
        leftMaskView.alpha = 0.7
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(leftMaskView, belowSubview: leftHandleView)

        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true

        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = .white
        rightMaskView.alpha = 0.7
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)

        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }

    private func setupPositionBar() {

        positionBar.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
        positionBar.backgroundColor = positionBarColor
        positionBar.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
        positionBar.layer.cornerRadius = 1
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.isUserInteractionEnabled = false
        addSubview(positionBar)

        positionBar.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
        positionBar.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
        positionConstraint?.isActive = true
    }

    private func setupGestures() {

        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
    }

    private func updateMainColor() {
        trimView.layer.borderColor = mainColor.cgColor
        leftHandleView.backgroundColor = mainColor
        rightHandleView.backgroundColor = mainColor
    }

    private func updateHandleColor() {
        leftHandleKnob.backgroundColor = handleColor
        rightHandleKnob.backgroundColor = handleColor
    }

    // MARK: - Trim Gestures

    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
        let isLeftGesture = view == leftHandleView
        switch gestureRecognizer.state {

        case .began:
            if isLeftGesture {
                currentLeftConstraint = leftConstraint!.constant
            } else {
                currentRightConstraint = rightConstraint!.constant
            }
            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            layoutIfNeeded()
            if let startTime = startTime, isLeftGesture {
                seek(to: startTime, isLeftGesture: isLeftGesture)
            } else if let endTime = endTime {
                seek(to: endTime, isLeftGesture: isLeftGesture)
            }
            updateSelectedTime(stoppedMoving: false)

            guard let startTime = startTime,
                let endTime = endTime else { return }
            let duration = (endTime - startTime).seconds
            if duration > maxDuration, let sideConstraint = sideConstraint {
                if isLeftGesture {
                    rightConstraint?.constant -= sideConstraint
                } else {
                    leftConstraint?.constant += sideConstraint
                }
            }
            layoutIfNeeded()
        case .cancelled, .ended, .failed:
            updateSelectedTime(stoppedMoving: true)
        default: break
        }
    }

    private func isValidTranslation(isLeftGesture: Bool, with translation: CGPoint) -> Bool {
        if isLeftGesture {
            if currentLeftConstraint + translation.x > 0 { return true }
        } else {
            if currentRightConstraint + translation.x < 0 { return true }
        }
        return false
    }

    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        if let constant = leftConstraint?.constant {
            sideConstraint = constant - newConstraint
        }
        leftConstraint?.constant = newConstraint
    }

    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
        let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        if let constant = rightConstraint?.constant {
            sideConstraint = newConstraint - constant
        }
        rightConstraint?.constant = newConstraint
    }

    // MARK: - Asset loading

    override func assetDidChange(newAsset: AVAsset?) {
        super.assetDidChange(newAsset: newAsset)
        resetHandleViewPosition()

        guard let maxTranslation = maxTranslation(isLeftGesture: true) else { return }
        updateRightConstraint(with: maxTranslation)
        layoutIfNeeded()
    }

    private func resetHandleViewPosition() {
        leftConstraint?.constant = 0
        rightConstraint?.constant = 0
        layoutIfNeeded()
    }

    // MARK: - Time Equivalence

    /// Move the position bar to the given time.
    public func seek(to time: CMTime, isLeftGesture: Bool) {
        if let newPosition = getPosition(from: time) {
            let offsetPosition = newPosition - assetPreview.contentOffset.x - leftHandleView.frame.origin.x
            let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth)
                - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            positionConstraint?.constant = normalizedPosition
            layoutIfNeeded()
        }
    }

    /// The selected start time for the current asset.
    public var startTime: CMTime? {
        let startPosition = leftHandleView.frame.origin.x + assetPreview.contentOffset.x
        return getTime(from: startPosition)
    }

    /// The selected end time for the current asset.
    public var endTime: CMTime? {
        let endPosition = rightHandleView.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: endPosition)
    }

    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
        }
    }

    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: barPosition)
    }

    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }

    // MARK: - Scroll View Delegate

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedTime(stoppedMoving: true)
        }
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: false)
    }

    func maxTranslation(isLeftGesture: Bool) -> CGPoint? {
        guard let timeScale = asset?.duration.timescale,
            let currentStartTime = startTime,
            let currentEndTime = endTime,
            (currentEndTime.seconds - currentStartTime.seconds) > maxDuration else { return nil }
        if isLeftGesture {
            let endSecond = currentStartTime.seconds + maxDuration
            let endTime = CMTime(seconds: endSecond, preferredTimescale: timeScale)
            let currentEndposition = getPosition(from: currentEndTime) ?? 0
            let endPosition = getPosition(from: endTime) ?? 0
            return CGPoint(x: endPosition - currentEndposition, y: 0)
        } else {
            let startSecond = currentEndTime.seconds - maxDuration
            let startTime = CMTime(seconds: startSecond, preferredTimescale: timeScale)
            let currentStartPosition = getPosition(from: currentStartTime) ?? 0
            let startPosition = getPosition(from: startTime) ?? 0
            return CGPoint(x: startPosition - currentStartPosition, y: 0)
        }
    }
    
    func trimTime() -> (startTime: CMTime, endTime: CMTime)? {
        guard let timeScale = asset?.duration.timescale,
            let startTime = self.startTime,
            let endTime = self.endTime else { return nil }
        let duration = (endTime - startTime).seconds
        if duration < maxDuration {
            return (startTime: startTime, endTime: endTime)
        }
        let overDuration = (duration - maxDuration) / 2
        return (startTime: CMTime(seconds: startTime.seconds - overDuration,
                                  preferredTimescale: timeScale),
                endTime: CMTime(seconds: endTime.seconds - overDuration,
                                preferredTimescale: timeScale))
    }
}
