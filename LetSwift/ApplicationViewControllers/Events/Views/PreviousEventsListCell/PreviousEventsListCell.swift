//
//  PreviousEventsListCell.swift
//  LetSwift
//
//  Created by Marcin Chojnacki, Kinga Wilczek on 28.04.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import UIKit

final class PreviousEventsListCell: UITableViewCell, Localizable {

    @IBOutlet private weak var eventsCollectionView: UICollectionView!
    @IBOutlet private weak var previousTitleLabel: UILabel!
    @IBOutlet private weak var spinnerView: SpinnerView!
    @IBOutlet private weak var scrollViewTrailingConstraint: NSLayoutConstraint!

    private var isMoreEventsRequested = false
    private var isScrollViewDragging = false
    private let disposeBag = DisposeBag()

    var viewModel: PreviousEventsListCellViewModel! {
        didSet {
            if viewModel != nil && viewModel !== oldValue {
                reactiveSetup()
            }
        }
    }

    var isSpinnerVisibleOnScreen: Bool {
        return bounds.contains(convert(spinnerView.bounds, from: spinnerView))
    }

    var isMorePreviousEventsRequestAllowed: Bool {
        return isMoreEventsRequested && !spinnerView.isHidden && isSpinnerVisibleOnScreen
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setup()
    }
    
    private func setup() {
        removeSeparators()

        eventsCollectionView.registerCells([PreviousEventCell.self])

        spinnerView.image = #imageLiteral(resourceName: "WhiteSpinner")
        spinnerView.backgroundColor = .clear

        setupLocalization()
    }
    
    func setupLocalization() {
        previousTitleLabel.text = localized("EVENTS_PREVIOUS").uppercased()
    }

    private func reactiveSetup() {
        viewModel.previousEventsObservable.subscribeNext(startsWithInitialValue: true) { [weak self] events in
            self?.scrollViewMoveWithAnimation(about: 0.0)
            self?.spinnerView.animationActive = true

            guard let collectionView = self?.eventsCollectionView else { return }
            events?.bindable.bind(to: collectionView.item(with: PreviousEventCell.cellIdentifier, cellType: PreviousEventCell.self) ({ index, element, cell in
                cell.imageURL = element?.coverImages.first?.thumb
                cell.title = element?.title
                cell.date = element?.date?.stringDateValue
            }))
        }
        .add(to: disposeBag)

        eventsCollectionView.itemDidSelectObservable.subscribeNext { [weak self] indexPath in
            self?.viewModel.cellDidTapWithIndexObservable.next(indexPath.item)
        }
        .add(to: disposeBag)

        eventsCollectionView.scrollViewDidScrollObservable.subscribeNext { [weak self] scrollView in
            guard let scrollView = scrollView, let weakSelf = self else { return }

            let boundsWidth = scrollView.bounds.width
            let insets = scrollView.contentInset
            let y = scrollView.contentOffset.x + boundsWidth - insets.right
            let additonalSpace: CGFloat = 65.0
            let spinnerOffset = y - scrollView.contentSize.width

            UIView.animate(withDuration: 0.01) {
                self?.spinnerView.transform = CGAffineTransform(translationX: -spinnerOffset, y: 0.0)
            }

            if (y > scrollView.contentSize.width + additonalSpace) && !weakSelf.spinnerView.isHidden {
                if weakSelf.isScrollViewDragging {
                    weakSelf.isMoreEventsRequested = true
                } else {
                    weakSelf.scrollViewMoveWithAnimation(about: 60.0)
                    weakSelf.viewModel.morePreviousEventsRequestObervable.next()
                }
            }
        }
        .add(to: disposeBag)

        eventsCollectionView.scrollViewWillEndDraggingObservable.subscribeNext { [weak self] in
            guard let weakSelf = self else { return }

            weakSelf.isScrollViewDragging = false
            if weakSelf.isMorePreviousEventsRequestAllowed {
                DispatchQueue.main.async {
                    weakSelf.scrollViewMoveWithAnimation(about: 60.0)
                }
                weakSelf.viewModel.morePreviousEventsRequestObervable.next()
                weakSelf.isMoreEventsRequested = false
            } else {
                weakSelf.scrollViewMoveWithAnimation(about: 0.0)
                weakSelf.viewModel.morePreviousEventsRequestCanceledObservable.next()
                weakSelf.isMoreEventsRequested = false
            }
        }
        .add(to: disposeBag)

        eventsCollectionView.scrollViewWillBeginDraggingObservable.subscribeNext { [weak self] in
            self?.isScrollViewDragging = true
        }
        .add(to: disposeBag)

        viewModel.shouldScrollToFirstObservable.subscribeNext { [weak self] in
            self?.restartCellState()
        }
        .add(to: disposeBag)

        viewModel.morePreviousEventsAvilabilityObservable.subscribeNext { [weak self] enable in
            self?.spinner(enable: enable)
        }
        .add(to: disposeBag)

        viewModel.morePreviousEventsRequestSentObservable.subscribeNext { [weak self] index in
            self?.eventsCollectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        }
        .add(to: disposeBag)
        
    }

    private func restartCellState() {
        let sectionNumber = 0
        guard eventsCollectionView.numberOfItems(inSection: sectionNumber) > 0 else { return }

        eventsCollectionView.scrollToItem(at: IndexPath(row: 0, section: sectionNumber), at: .right, animated: false)
        spinnerView.isHidden = false
    }

    private func spinner(enable: Bool) {
        DispatchQueue.main.async {
            self.scrollViewTrailingConstraint.constant = 0.0
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.spinnerView.isHidden = !enable
            })
        }
    }

    private func scrollViewMoveWithAnimation(about space: CGFloat) {
        scrollViewTrailingConstraint.constant = space
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
