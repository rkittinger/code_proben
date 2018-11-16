//
//  MyDatesInteractor.swift
//
//  Created by Randy Kittinger on 22.02.18.
//  Copyright © 2018 F&P GmbH. All rights reserved.
//

import Foundation

class MyDatesInteractor {

    // MARK: - Dependency Injection Properties

    var jcApi: JcAppApi!
    var meUserSyncService: MeUserSyncService!
    weak var interface: MyDatesViewController?

    // MARK: - Private Properties

    private var dateModel: MyDateModel?
    private var datesViewModel: DatesViewModel?
    private var apiError: JCAppApiError?
    private var lastSyncTimestamp: Date?

    // MARK: - Helpers

    func getMyDates(forceToUpdate: Bool = false) {

        if !forceToUpdate {
            let currentDate = Date()
            let lastSyncTime = self.lastSyncTimestamp ?? currentDate
            guard (Calendar.current.dateComponents([.minute], from: lastSyncTime, to: currentDate).minute ?? 0) > Constant.API.minPassedTimeToUpdateDates else {
                return
            }
        }

        self.lastSyncTimestamp = Date()

        self.dateModel = MyDateModel(dates: [])
        self.viewModelChanged(hideProgress: false)

        self.jcApi.myDates { (myDateResponse: MyDateResponse?, error: JCAppApiError?) in

            if let myDateResponse = myDateResponse {
                self.apiError = nil
                self.dateModel = MyDateModel(dates: myDateResponse.dates ?? [])
            } else {
                self.apiError = error
            }
            self.viewModelChanged()
        }
    }
}

// MARK: - Private Functions

private extension MyDatesInteractor {

    func viewModelChanged(hideProgress: Bool = true) {

        guard let dateModel = self.dateModel else {
            return
        }

        if let myUser = self.meUserSyncService.loadMeUserFromLocalStore() {
            self.datesViewModel = DatesViewModel.buildViewModelFromMyDateModel(dateModel: dateModel, myUser: myUser)
            self.interface?.refreshUIForDateViewModel(self.datesViewModel, apiError: self.apiError, hideProgress: hideProgress)
        }
    }
}

// MARK: - MyDateModel Struct

struct MyDateModel {

    var dates = [DateResponse]()

    init(dates: [DateResponse]) {
        self.dates = dates
    }
}
