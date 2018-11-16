//
//  DateListViewController.swift
//
//  Created by Randy Kittinger on 24.11.17.
//  Copyright © 2017 F&P GmbH. All rights reserved.
//

import UIKit

protocol ShowedFSK12WarningDelegate: class {

    func showedWarningDialogAccepted()
    func isWarningDialogAccepted() -> Bool
}

class DateListViewController: JCViewController {

    // MARK: - Outlets

    @IBOutlet private weak var datesCollectionView: UICollectionView!
    @IBOutlet weak var floatingActionButton: JoyFloatingActionButton!
    @IBOutlet weak var fabButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - UI Properties

    private var progressView: JOYProgressView?
    private var cellSize = CGSize.zero
    private var featuredCellSize = CGSize.zero

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        return refreshControl
    }()

    // MARK: - Dependency Injection Properties

    var interactor: DateInteractor!
    var applicationSettings: ApplicationSettings!

    // MARK: - Private Properties

    private var loadingMoreError: JCAppApiError?
    private var isLoadingMore: Bool = false
    private var datesViewModel: DatesViewModel?

    private let progressCellIdentifier = "ProgressCellIdentifier"
    private var isFSK12WarningDialogAccepted = false

    // MARK: - Instantiate

    static func instantiate() -> DateListViewController {
        return StoryboardScene.Discover.dateListViewController.instantiate()
    }

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {

        super.viewDidLoad()

        self.view.backgroundColor = AppColors.blackColorBackground
        self.initializeProgressView()
        self.setupCollectionView()

        self.interactor.startLastDateOrDefault(forceToUpdate: true)
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        self.interactor.startLastDateOrDefault()
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        self.floatingActionButton?.fadeIn()
        self.analytics().logEvent(.screen_dating_search_results)
    }

    // MARK: - Helper Methods

    func refreshUIForDateViewModel(_ datesViewModel: DatesViewModel?, initLoadingError: JCAppApiError?, loadingMoreError: JCAppApiError?, isLoadingMore: Bool, hideProgress: Bool) {

        DispatchQueue.main.async { [weak self] in

            self?.datesViewModel = datesViewModel
            self?.loadingMoreError = loadingMoreError
            self?.isLoadingMore = isLoadingMore

            self?.progressView?.isHidden = hideProgress
            self?.refreshControl.endRefreshing()

            self?.floatingActionButton?.isHidden = (datesViewModel?.dates.isEmpty ?? true) && (initLoadingError != nil)

            if (datesViewModel?.dates.isEmpty ?? true) {

                let noResultsView = SearchNoResultsView.instanceFromNib()

                if initLoadingError != nil {
                    noResultsView.configure(emptyStateType: .ErrorDateView) {
                        self?.interactor.startLastDateOrDefault(forceToUpdate: true)
                    }
                } else {
                    noResultsView.configure(emptyStateType: .DateView) {
                        self?.showSearchFilter()
                    }
                }

                self?.datesCollectionView?.backgroundView = noResultsView
            }

            self?.preCalculateCellsSize()
            self?.datesCollectionView?.reloadData()
        }
    }

    // MARK: - Actions

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.interactor.startLastDateOrDefault(forceToUpdate: true)
    }

    @IBAction func openFabMenu(_ sender: Any) {

        self.floatingActionButton?.alpha = 0.0

        let fabMenuItems = self.buildFabMenuItemsForFabType(.Dates)

        JoyFloatingActionViewController.presentFromViewController(sourceViewController: self, withDelegate: self, withMenuItems: fabMenuItems)
    }
}

// MARK: - JoyTabmanChildViewController

extension DateListViewController: JoyTabmanChildViewController {

    func scrollToTop(animated: Bool) {
        self.datesCollectionView?.scrollToTop(animated: animated)
    }

    func configureContentInsets(useHeartNav: Bool) {

        self.datesCollectionView?.contentInset = useHeartNav ? Constant.UI.FooterNavigation.contentInsertForHeartNavigation : Constant.UI.FooterNavigation.contentInsertForNavigation

        let bottomInset: CGFloat = useHeartNav ? Constant.UI.FooterNavigation.heartFooterBottomMargin : Constant.UI.FooterNavigation.footerBottomMargin
        self.fabButtonBottomConstraint?.constant = bottomInset
    }

    func showSearchFilter() {

        if let searchParameter = self.applicationSettings.getLastDateSearchParameter() {
            let filterViewController = DateFilterViewController.instantiate(searchParameter: searchParameter, dateFilterChangedDelegate: self)
            self.navigationController?.pushViewController(filterViewController, animated: true)
        }
    }
}

extension DateListViewController: DateFilterChangedDelegate {

    func onDateSearchParameterChanged(_ searchParameter: DateParameter) {

        self.navigateBack()
        self.datesCollectionView?.collectionViewLayout.invalidateLayout()
        self.datesCollectionView?.scrollToTop(animated: true)
        self.progressView?.isHidden = false
        self.interactor?.startSearch(searchParameter)
    }
}

// MARK: - Private Helpers

private extension DateListViewController {

    func setupCollectionView() {

        self.datesCollectionView?.backgroundColor = AppColors.blackColorBackground

        self.datesCollectionView?.registerNib(SearchDateCollectionViewCell.self)
        self.datesCollectionView?.registerNib(FeaturedDateCollectionViewCell.self)
        self.datesCollectionView?.addSubview(self.refreshControl)

        self.configureContentInsets(useHeartNav: self.applicationSettings.getUseHeartNavigation())
    }

    func initializeProgressView() {

        self.progressView = Bundle.main.loadNibNamed("JOYProgressView", owner: self, options: nil)?.first as? JOYProgressView
        self.progressView?.progressMsgLabel.text = L10n.progressSearchMsg
        self.progressView?.frame = self.view.bounds
        self.progressView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.progressView?.isHidden = false

        if let progressView = self.progressView {
            self.view.addSubview(progressView)
        }
    }

    func preCalculateCellsSize() {

        if let cellSpacing = (self.datesCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing,
            let frameWidth = self.datesCollectionView?.frame.size.width {

            let availableWidth = frameWidth - cellSpacing

            let featuredCellWidth = availableWidth - cellSpacing
            self.featuredCellSize = CGSize(width: featuredCellWidth, height: (featuredCellWidth * 0.5))

            let cellWidth = (availableWidth * 0.5) - cellSpacing
            self.cellSize = CGSize(width: cellWidth, height: (Constant.UI.SearchResult.ImageRatio * cellWidth) + Constant.UI.DateResult.imageBottomSpace)
        }
    }
}

// MARK: - MyDatesDelegate

extension DateListViewController: MyDatesDelegate {

    func myDateChangedForViewModel(_ viewModel: DateViewModel) {

        var isDateUpdated = false

        for (index, dateViewModel) in (self.datesViewModel?.dates ?? []).enumerated() where (dateViewModel.date.dateId == viewModel.date.dateId) {
            self.datesViewModel?.dates[index] = viewModel
            self.datesCollectionView?.reloadData()
            isDateUpdated = true
        }

        if !isDateUpdated {
            self.interactor.startLastDateOrDefault(forceToUpdate: true)
        }
    }

    func myDateDeletedForId(_ dateId: Int) {

        for (index, dateViewModel) in (self.datesViewModel?.dates ?? []).enumerated() where (dateViewModel.date.dateId == dateId) {
            self.datesViewModel?.dates.remove(at: index)

            if self.datesViewModel?.dates.isEmpty ?? true {
                let noResultsView = SearchNoResultsView.instanceFromNib()
                noResultsView.configure(emptyStateType: .MyDateView)
                self.datesCollectionView?.backgroundView = noResultsView
            }

            self.datesCollectionView?.reloadData()
            return
        }
    }
}

// MARK: - JoyFloatingActionDelegate

extension DateListViewController: JoyFloatingActionDelegate {

    func menuDidClose() {
        self.floatingActionButton?.alpha = 1.0
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension DateListViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {

        if !(self.datesViewModel?.dates.isEmpty ?? true) {
            collectionView.backgroundView = nil
        }

        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datesViewModel?.dates.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DateDetailViewController.presentFromViewController(sourceViewController: self, dateViewModel: self.datesViewModel?.dates[indexPath.row], showedFSK12WarningDelegate: self, votingDelegate: self)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: SearchDateCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

        if let dateViewModel = self.datesViewModel?.dates[indexPath.row] {
            if indexPath.row == 0 && dateViewModel.featured ?? false {
                let featuredCell: FeaturedDateCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                featuredCell.configureForDate(dateViewModel, userContentClassification: self.meUserService.loadMeUserFromLocalStore()?.contentClassification)
                return featuredCell
            } else {
                cell.configureForDate(dateViewModel, userContentClassification: self.meUserService.loadMeUserFromLocalStore()?.contentClassification)
            }

            if (indexPath.row >= (self.datesViewModel?.dates.count ?? 0) - Constant.API.SearchResult.offsetToLoadMore) {
                self.interactor.loadMore()
            }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DateListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let cellSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing else {
            return CGSize.zero
        }

        if (indexPath.section == 1) {
            let availableWidth = collectionView.frame.size.width - cellSpacing
            return CGSize(width: availableWidth, height: self.view.frame.height)
        }

        if let dateViewModel = self.datesViewModel?.dates[indexPath.row],
           (indexPath.row == 0 && dateViewModel.featured ?? false) {

            return self.featuredCellSize
        } else {
            return self.cellSize
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {

        case UICollectionElementKindSectionFooter:
            guard let loadingMoreCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.progressCellIdentifier, for: indexPath) as? LoadingMoreCollectionViewCell else {
                return UICollectionReusableView()
            }

            loadingMoreCell.configure(self.loadingMoreError)
            loadingMoreCell.retryHandler = {
                self.interactor.retryLoadMore()
            }

            return loadingMoreCell
        default:
            fatalError("Unexpected element kind")
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {

        guard let cellSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing else {
            return CGSize.zero
        }

        let availableWidth = collectionView.frame.size.width - cellSpacing

        let isLoadingMoreOrRetryCellVisible = (self.isLoadingMore || self.loadingMoreError != nil)
        let availableHeight: CGFloat = (isLoadingMoreOrRetryCellVisible ? Constant.UI.DateResult.loadOrReloadCellHeight : 0)
        return CGSize(width: availableWidth, height: availableHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Constant.UI.DateResult.collectionViewEdgeInsets
    }
}

// MARK: - ShowedFSK12WarningDelegate

extension DateListViewController: ShowedFSK12WarningDelegate {

    func showedWarningDialogAccepted() {
        self.isFSK12WarningDialogAccepted = true
    }

    func isWarningDialogAccepted() -> Bool {
        return self.isFSK12WarningDialogAccepted
    }
}

// MARK: - ProfileVotingDelegate

extension DateListViewController: ProfileVotingDelegate {

    func votingChangedWithVote(_ vote: Int?, forUserId userId: Int?) {

        if let dates = self.datesViewModel?.dates {
            var reloadIsNeeded = false

            for date in dates where (date.user.id == userId) {
                date.myVoting = vote
                reloadIsNeeded = true
            }

            if reloadIsNeeded {
                self.datesCollectionView?.reloadData()
            }
        }
    }
}
