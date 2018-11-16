//
//  DashboardService.swift
//
//  Created by Randy Kittinger on 09.09.16.
//  Copyright © 2016 F&P GmbH. All rights reserved.
//

import Foundation
import CocoaLumberjack

class FeedListSyncObserverWrapper {

    weak var observer: FeedListSyncObserver?

    init(observer: FeedListSyncObserver) {
        self.observer = observer
    }
}

protocol FeedListSyncObserver: class {

    var description: String { get }

    func onFeedsChanged()
    func onFeedsLoadedError(_ error: JobError)
    func onFeedDeleted()
    func onRegioFeedsChanged()
    func onRegioFeedsLoadedError(_ error: JobError)
    func onRegioFeedDeleted()
}

extension FeedListSyncObserver {

    func onFeedsChanged() {}
    func onFeedsLoadedError(_ error: JobError) {}
    func onFeedDeleted() {}
    func onRegioFeedsChanged() {}
    func onRegioFeedsLoadedError(_ error: JobError) {}
    func onRegioFeedDeleted() {}
}

class DashboardService: NSObject {

    var jcApi: JcAppApi!
    var dashboardStore: DashboardStore!
    var appSettings: ApplicationSettings!
    var attachmentService: AttachmentService!
    var attachmentStore: AttachmentStore!
    var feedListSyncObservers: [String: FeedListSyncObserverWrapper] = [:]

    private var updateAllFeedsInProgress = false
    private var updateRegioFeedsInProgress = false

    func registerFeedListSyncObserver(_ observer: FeedListSyncObserver) {
        self.feedListSyncObservers[observer.description] = FeedListSyncObserverWrapper(observer: observer)
    }

    func unregisterFeedListSyncObserver(_ observer: FeedListSyncObserver) {
        self.feedListSyncObservers.removeValue(forKey: observer.description)
    }

    func notifyFeedListChanged() {

        DispatchQueue.main.async {
            for feedListObserver in self.feedListSyncObservers.values {
                feedListObserver.observer?.onFeedsChanged()
            }
        }
    }

    func notifyFeedListError(_ error: JobError) {

        DispatchQueue.main.async {
            for feedListObserver in self.feedListSyncObservers.values {
                feedListObserver.observer?.onFeedsLoadedError(error)
            }
        }
    }

    func notifyRegioFeedListChanged() {

        DispatchQueue.main.async {
            for feedListObserver in self.feedListSyncObservers.values {
                feedListObserver.observer?.onRegioFeedsChanged()
            }
        }
    }

    func notifyRegioFeedListError(_ error: JobError) {

        DispatchQueue.main.async {
            for feedListObserver in self.feedListSyncObservers.values {
                feedListObserver.observer?.onRegioFeedsLoadedError(error)
            }
        }
    }

    func updateAllFeeds(_ limit: Int, forLastFeedKey: Int64? = nil, silentUpdate: Bool) {

        if self.updateAllFeedsInProgress {
            return
        }

        self.updateAllFeedsInProgress = true
        let updateAllFeeds = UpdateFeedListJob(withApi: self.jcApi, withStore: self.dashboardStore, withLimit: limit, forFeedSources: [.User, .Friend], forLastFeedKey: forLastFeedKey, silentUpdate: silentUpdate)

        updateAllFeeds.executeAsync({
            self.updateAllFeedsInProgress = false
            self.notifyFeedListChanged()
            }, onError: { error in
                self.updateAllFeedsInProgress = false
                self.notifyFeedListError(error)
        })
    }

    func updateRegioFeeds(_ limit: Int, forLastFeedKey: Int64? = nil, lon: Float? = nil, lat: Float? = nil) {

        if self.updateRegioFeedsInProgress {
            return
        }
        self.updateRegioFeedsInProgress = true
        let updateRegioFeeds = UpdateFeedListJob(withApi: self.jcApi, withStore: self.dashboardStore, withLimit: limit, forFeedSources: [.Region], forLastFeedKey: forLastFeedKey, lon: lon, lat: lat)
        updateRegioFeeds.executeAsync({
            self.updateRegioFeedsInProgress = false
            self.notifyRegioFeedListChanged()
        }, onError: { error in
            self.updateRegioFeedsInProgress = false
            self.notifyRegioFeedListError(error)
        })
    }

    func deleteFeed(_ feed: DashboardViewModel, completion: @escaping (Bool, JCAppApiError?) -> Void) {

        let deleteFeed = DeleteFeedJob(feed: feed, withApi: self.jcApi, withStore: self.dashboardStore)
        deleteFeed.executeAsync({
            completion(true, nil)
        }, onError: { (error: JobError) in
            completion(false, error.apiError)
        })
    }
}
