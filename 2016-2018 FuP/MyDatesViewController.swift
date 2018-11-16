//
//  MyDatesViewController.swift
//
//  Created by Randy Kittinger on 22.02.18.
//  Copyright © 2018 F&P GmbH. All rights reserved.
//

import UIKit
import CocoaLumberjack

protocol MyDatesDelegate: class {

    func myDateChangedForViewModel(_ viewModel: DateViewModel)
    func myDateDeletedForId(_ dateId: Int)
}

class MyDatesViewController: JCViewController {

    // MARK: - Outlets

    @IBOutlet private weak var datesCollectionView: UICollectionView?
    @IBOutlet private weak var floatingActionButton: UIButton?

    // MARK: - UI Properties

    private var progressView: JOYProgressView?
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        return refreshControl
    }()

    // MARK: - Dependency Injection Properties

    var interactor: MyDatesInteractor!
    var applicationSettings: ApplicationSettings!

    // MARK: - Properties

    private var datesViewModel: DatesViewModel?
    weak var myDatesDelegate: MyDatesDelegate?

    // MARK: - Instantiate

    static func instantiate() -> MyDatesViewController {
        return StoryboardScene.Discover.myDatesViewController.instantiate()
    }

    static func presentFromViewController(sourceViewController: UIViewController?, forDateViewModel dateViewModel: DateViewModel? = nil, myDatesDelegate: MyDatesDelegate? = nil) {

        let myDatesViewController = MyDatesViewController.instantiate()
        myDatesViewController.myDatesDelegate = myDatesDelegate

        let navigationController = UINavigationController(rootViewController: myDatesViewController)
        sourceViewController?.present(navigationController, animated: true, completion: nil)
    }

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {

        super.viewDidLoad()

        self.setupUI()
        self.initializeProgressView()
        self.setupCollectionView()

        self.interactor.getMyDates(forceToUpdate: true)
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        self.interactor.getMyDates()
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        self.analytics().logEvent(.screen_dating_my_dates)
    }

    // MARK: - Helper Methods

    func refreshUIForDateViewModel(_ datesViewModel: DatesViewModel?, apiError: JCAppApiError?, hideProgress: Bool) {
        DispatchQueue.main.async { [weak self] in

            guard let strongSelf = self else {
                return
            }

            strongSelf.datesViewModel = datesViewModel

            strongSelf.floatingActionButton?.isHidden = (datesViewModel?.dates.isEmpty ?? true) && (apiError != nil)

            strongSelf.progressView?.isHidden = hideProgress
            strongSelf.refreshControl.endRefreshing()

            if (datesViewModel?.dates.isEmpty ?? true) {
                let noResultsView = SearchNoResultsView.instanceFromNib()

                if apiError != nil {
                    noResultsView.configure(emptyStateType: .ErrorMyDateView) {
                        strongSelf.interactor.getMyDates(forceToUpdate: true)
                    }
                } else {
                    noResultsView.configure(emptyStateType: .MyDateView)
                }

                strongSelf.datesCollectionView?.backgroundView = noResultsView
            }

            strongSelf.datesCollectionView?.reloadData()
            strongSelf.datesCollectionView?.collectionViewLayout.invalidateLayout()
            strongSelf.datesCollectionView?.scrollToTop(animated: true)
        }
    }

    // MARK: - Private Helper Methods

    private func setupUI() {

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: AppImages.arrowLeft(), style: .plain, target: self, action: #selector(back(_:)))
        self.title = L10n.myDatesTitle
        self.view.backgroundColor = AppColors.blackColorBackground
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = AppColors.blackColorHeader
    }

    // MARK: - Actions

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.interactor.getMyDates(forceToUpdate: true)
    }

    @objc func back(_ sender: UIBarButtonItem? = nil) {
        self.navigateBack()
    }

    @IBAction func createDateButtonTapped(_ sender: Any) {
        CreateDateViewController.presentFromViewController(sourceViewController: self, myDatesChangedDelegate: self)
    }
}

// MARK: - JoyTabmanChildViewController

extension MyDatesViewController: JoyTabmanChildViewController {

    func scrollToTop(animated: Bool) {
        self.datesCollectionView?.scrollToTop(animated: animated)
    }

    func configureContentInsets(useHeartNav: Bool) {
        self.datesCollectionView?.contentInset = useHeartNav ? Constant.UI.FooterNavigation.contentInsertForHeartNavigation : Constant.UI.FooterNavigation.contentInsertForNavigation
    }
}

// MARK: - Private Helpers

private extension MyDatesViewController {

    func setupCollectionView() {

        self.datesCollectionView?.backgroundColor = AppColors.blackColorBackground

        self.datesCollectionView?.registerNib(SearchDateCollectionViewCell.self)
        self.datesCollectionView?.addSubview(self.refreshControl)
        self.configureContentInsets(useHeartNav: self.applicationSettings.getUseHeartNavigation())
    }

    func initializeProgressView() {

        self.progressView = Bundle.main.loadNibNamed("JOYProgressView", owner: self, options: nil)?.first as? JOYProgressView
        self.progressView?.progressMsgLabel.text = L10n.progressSearchMsg
        self.progressView?.frame = view.bounds
        self.progressView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.progressView?.isHidden = false

        if let progressView = self.progressView {
            self.view.addSubview(progressView)
        }
    }
}

extension MyDatesViewController: MyDatesDelegate {

    func myDateChangedForViewModel(_ viewModel: DateViewModel) {

        var isDateUpdated = false

        // Also update main date list
        self.myDatesDelegate?.myDateChangedForViewModel(viewModel)

        for (index, dateViewModel) in (self.datesViewModel?.dates ?? []).enumerated() where (dateViewModel.date.dateId == viewModel.date.dateId) {
            self.datesViewModel?.dates[index] = viewModel
            self.datesCollectionView?.reloadData()
            isDateUpdated = true
        }

        if !isDateUpdated {
            self.interactor.getMyDates(forceToUpdate: true)
        }
    }

    func myDateDeletedForId(_ dateId: Int) {

        // Also update main date list
        self.myDatesDelegate?.myDateDeletedForId(dateId)

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

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension MyDatesViewController: UICollectionViewDelegate, UICollectionViewDataSource {

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

        let date = self.datesViewModel?.dates[indexPath.row]
        DateDetailViewController.presentFromViewController(sourceViewController: self, dateViewModel: date, showedFSK12WarningDelegate: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: SearchDateCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

        // own dates should always be cleared for FSK 16 content
        if let dateViewModel = self.datesViewModel?.dates[indexPath.row] {
            cell.configureForDate(dateViewModel, userContentClassification: .fsk16)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Constant.UI.DateResult.collectionViewEdgeInsets
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MyDatesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let cellSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing else {
            return CGSize.zero
        }

        let availableWidth = collectionView.frame.size.width - cellSpacing

        if (indexPath.section == 1) {
            return CGSize(width: availableWidth, height: self.view.frame.height)
        }

        let width = (availableWidth * 0.5) - cellSpacing

        return CGSize(width: width, height: (Constant.UI.SearchResult.ImageRatio * width) + Constant.UI.DateResult.imageBottomSpace)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {

        guard let cellSpacing = (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing else {
            return CGSize.zero
        }

        let availableWidth = collectionView.frame.size.width - cellSpacing

        return CGSize(width: availableWidth, height: 0)
    }
}
