//
//  DateInteractor.swift
//
//  Created by Randy Kittinger on 24.11.17.
//  Copyright © 2017 F&P GmbH. All rights reserved.
//

import Foundation

class DateInteractor {

    // MARK: - Dependency Injection Properties

    var jcApi: JcAppApi!
    var appSettings: ApplicationSettings!
    weak var interface: DateListViewController?

    // MARK: - Private Properties

    private var dateModel: DateModel?
    private var datesViewModel: DatesViewModel?
    private var isLoadingMore: Bool = false
    private var initLoadingError: JCAppApiError?
    private var loadingMoreError: JCAppApiError?
    private var lastSyncTimestamp: Date?

    private var isLoadingMoreError: Bool {
        return loadingMoreError != nil
    }

    // MARK: - Helpers

    func startLastDateOrDefault(forceToUpdate: Bool = false) {

        if !forceToUpdate {
            let currentDate = Date()
            let lastSyncTime = self.lastSyncTimestamp ?? currentDate

            guard (Calendar.current.dateComponents([.minute], from: lastSyncTime, to: currentDate).minute ?? 0) > Constant.API.minPassedTimeToUpdateDates else {
                return
            }
        }

        self.lastSyncTimestamp = Date()
        self.loadLastDateOrDefault { (dateParameter: DateParameter?, error: JCAppApiError?) in

            if let dateParameter = dateParameter {
                self.startSearch(dateParameter)
            } else {
                DispatchQueue.main.async {

                    self.loadingMoreError = nil
                    self.initLoadingError = error

                    self.interface?.showError(apiError: error, analyticsEvent: .errorSearchDates)
                    self.interface?.refreshUIForDateViewModel(nil, initLoadingError: self.initLoadingError, loadingMoreError: nil, isLoadingMore: false, hideProgress: true)
                }
            }
        }
    }

    func loadMore() {

        guard !self.isLoadingMore && !self.dateModel!.endReached && !self.isLoadingMoreError else {
            return
        }
        self.internalLoadMore()
    }

    func retryLoadMore() {

        loadingMoreError = nil
        self.internalLoadMore()
    }

    func startSearch(_ dateParameter: DateParameter!, saveSearchParameters: Bool = true) {

        self.dateModel = DateModel(dateParameter: dateParameter)
        self.viewModelChanged(hideProgress: false)
        if saveSearchParameters {
            self.appSettings.saveDatesSearchParameter(dateParameter)
        }

        self.jcApi.searchDate(dateParameter, offset: dateModel!.offset, count: dateModel!.limit) { (searchDateResponse: SearchDateResponse?, error: JCAppApiError?) in

            if let searchDateResponse = searchDateResponse {
                self.initLoadingError = nil

                if let model = self.dateModel {
                    self.dateModel?.endReached = ((searchDateResponse.dates?.count ?? 0) < model.limit)
                    self.dateModel?.dates += searchDateResponse.dates ?? []
                    searchDateResponse.userMap?.forEach({ (key: String, userResponse: UserResponse) in
                        let userEntity = ApiToDataModelConverter.userToEntity(userResponse)
                        self.dateModel?.userMap[key] = userEntity
                    })
                    self.dateModel?.offset += model.limit
                }
            } else {
                self.loadingMoreError = nil
                self.initLoadingError = error
            }
            self.viewModelChanged()
        }
    }
}

// MARK: - Private Functions

private extension DateInteractor {

    func viewModelChanged(hideProgress: Bool = true) {

        guard let dateModel = self.dateModel else {
            return
        }

        let contentClassification = self.interface?.meUserService.loadMeUserFromLocalStore()?.contentClassification ?? .Unknown
        self.datesViewModel = DatesViewModel.buildViewModelFromDateModel(dateModel: dateModel, contentClassification: contentClassification)
        self.interface?.refreshUIForDateViewModel(self.datesViewModel, initLoadingError: self.initLoadingError, loadingMoreError: self.loadingMoreError, isLoadingMore: self.isLoadingMore && !(self.dateModel?.endReached ?? false), hideProgress: hideProgress)
    }

    // MARK: - API Calls

    func loadLastDateOrDefault(completion: @escaping (DateParameter?, JCAppApiError?) -> Void) {

        if let dateParameter = self.appSettings.getLastDateSearchParameter() {
            completion(dateParameter, nil)
        } else if let searchParameter = appSettings.getLastSearchParameter() {
            let dateParameter = DateParameter.createDateParameterFromSearchParameter(searchParameter)
            // set static values here as default, even if API or default user Search Parameter says differently
            dateParameter.withImage = false
            completion(dateParameter, nil)
        } else {
            jcApi.defaultSearch { (searchParameter, error) in
                if let params = searchParameter {
                    // set static values here as default, even if API says differently
                    let dateParameter = DateParameter.createDateParameterFromSearchParameter(params)
                    dateParameter.distance = Constant.UserFilter.Distance.defaultDistance
                    completion(dateParameter, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }

    func internalLoadMore() {

        guard let dateModel = self.dateModel else {
            return
        }
        self.isLoadingMore = true
        self.viewModelChanged()

        self.jcApi.searchDate(dateModel.dateParameter, offset: dateModel.offset, count: dateModel.limit) { (searchDateResponse: SearchDateResponse?, error: JCAppApiError?) in

            if let searchDateResponse = searchDateResponse {
                self.dateModel?.endReached = ((searchDateResponse.dates?.count ?? 0) < dateModel.limit)
                self.dateModel?.offset += dateModel.limit
                self.dateModel?.dates += searchDateResponse.dates ?? []
                searchDateResponse.userMap?.forEach({ (key: String, userResponse: UserResponse) in
                    let userEntity = ApiToDataModelConverter.userToEntity(userResponse)
                    self.dateModel?.userMap[key] = userEntity
                })

            } else {
                self.loadingMoreError = error
            }

            self.viewModelChanged()
            self.isLoadingMore = false
        }
    }
}

// MARK: - DateModel Struct

struct DateModel {

    var offset: Int = 0
    var limit: Int = Constant.API.maximumDatesPerAPICall
    var dates = [DateResponse]()
    var userMap = [String: UserEntity]()
    var endReached: Bool = false
    let dateParameter: DateParameter

    init(dateParameter: DateParameter) {
        self.dateParameter = dateParameter
    }
}
