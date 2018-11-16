//
//  DashboardStore.swift
//
//  Created by Randy Kittinger on 09.09.16.
//  Copyright © 2016 F&P GmbH. All rights reserved.
//

import Foundation
import CocoaLumberjack
import RealmSwift

class DashboardStoreObserverWrapper {

    weak var observer: DashboardStoreObserver?

    init(observer: DashboardStoreObserver) {
        self.observer = observer
    }
}

protocol DashboardStoreObserver: class {

    var description: String { get }

    func onFeedsChanged(_ feedKeys: [Int64]?)
    func onFeedsDeleted(_ feedKeys: [Int64])
    func onRegioFeedsChanged(_ feedKeys: [Int64]?)
    func onRegioFeedsDeleted(_ feedKeys: [Int64])
}

extension DashboardStoreObserver {

    func onFeedsChanged(_ feedKeys: [Int64]?) {}
    func onFeedsDeleted(_ feedKeys: [Int64]) {}
    func onRegioFeedsDeleted(_ feedKeys: [Int64]) {}
    func onRegioFeedsChanged(_ feedKeys: [Int64]?) {}
}

class DashboardStore: Store {

    var dashboardStoreObservers: [String: DashboardStoreObserverWrapper] = [:]

    // MARK: - Helpers

    func registerObserver(_ observer: DashboardStoreObserver) {

        DDLogDebug("\(observer) registered on \(self)")
        self.dashboardStoreObservers[observer.description] = DashboardStoreObserverWrapper(observer: observer)
    }

    func unregisterObserver(_ observer: DashboardStoreObserver) {

        DDLogDebug("\(observer) unregistered from \(self)")
        self.dashboardStoreObservers.removeValue(forKey: observer.description)
    }

    // needed for deleting
    func getFeedForFeedKey(_ feedKey: Int64) -> FeedEntity? {
        return self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "feedKey == %lld", feedKey)).first
    }

    func getAllFeeds(_ forFeedSources: [FeedSource], sorted: Bool? = false) -> [FeedEntity]? {

        let sourcesAsStrings = feedSourcesAsString(forFeedSource: forFeedSources)

        guard sorted == false else {
            return self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "internalFeedSource IN %@", sourcesAsStrings)).sorted(byKeyPath: "createTime", ascending: false).toArray()
        }

        return self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "internalFeedSource IN %@", sourcesAsStrings)).toArray()
    }

    func getNewestFeed() -> FeedEntity? {
        return self.getAllFeeds([.User, .Friend], sorted: true)?.first
    }

    func getFeedUserWithId(_ id: Int) -> UserEntity? {
        return self.realm.objects(UserEntity.self).filter(NSPredicate(format: "id == %i", id)).first
    }

    func getFeedUserWithAnonymousId(_ id: String) -> UserEntity? {
        return self.realm.objects(UserEntity.self).filter(NSPredicate(format: "anonymousUserId == %@", id)).first
    }

    func getProfileVisitorsWithFeedKey(_ parentFeedKey: Int64) -> [ProfileVisitorEntity]? {
        return self.realm.objects(ProfileVisitorEntity.self).filter(NSPredicate(format: "parentFeedKey == %lld", parentFeedKey)).toArray()
    }

    func getAllFeedEvents(_ forFeedSource: [FeedSource]) -> [FeedEventEntity]? {

        let sourcesAsStrings = feedSourcesAsString(forFeedSource: forFeedSource)
        return self.realm.objects(FeedEventEntity.self).filter(NSPredicate(format: "internalFeedSource IN %@", sourcesAsStrings)).toArray()
    }

    func getAllFeedPhotos(_ forFeedSource: [FeedSource]) -> [FeedPhotoEntity]? {

        let sourcesAsStrings = feedSourcesAsString(forFeedSource: forFeedSource)
        return self.realm.objects(FeedPhotoEntity.self).filter(NSPredicate(format: "internalFeedSource IN %@", sourcesAsStrings)).toArray()
    }

    func getFeedEventsWithFeedKey(_ parentFeedKey: Int64) -> [FeedEventEntity]? {
        return self.realm.objects(FeedEventEntity.self).filter(NSPredicate(format: "parentFeedKey == %lld", parentFeedKey)).toArray()
    }

    func getFeedPhotosForParentFeedKey(_ parentFeedKey: Int64) -> [FeedPhotoEntity]? {
        return self.realm.objects(FeedPhotoEntity.self).filter(NSPredicate(format: "parentFeedKey == %lld", parentFeedKey)).toArray()
    }

    func removeAllFeeds() {

        var feedKeys = [Int64]()
        try? self.realm.write {
            let feedEntities = self.realm.objects(FeedEntity.self)

            for feedEntity in feedEntities {
                feedKeys.append(feedEntity.feedKey)
                self.realm.delete(feedEntity)
            }

            let feedEventEntities = self.realm.objects(FeedEventEntity.self)

            for feedEventEntity in feedEventEntities {
                self.realm.delete(feedEventEntity)
            }

            let feedPhotoEntities = self.realm.objects(FeedPhotoEntity.self)

            for feedPhotoEntity in feedPhotoEntities {
                self.realm.delete(feedPhotoEntity)
            }

            let profileVisitorEntities = self.realm.objects(ProfileVisitorEntity.self)

            for profileVisitorEntity in profileVisitorEntities {
                self.realm.delete(profileVisitorEntity)
            }
        }
        self.notifyFeedsDeleted(feedKeys)
    }

    func removeFeedsForUserId(_ userId: Int, forFeedSource: FeedSource) {

        let feedEntities: [FeedEntity] = self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "userId == %i && internalFeedSource == %@", userId, forFeedSource.rawValue)).toArray()
        let feedKeys: [Int64] = self.extractFeedKeys(feedEntities)

        try! self.realm.write {
            self.realm.delete(feedEntities)

        }
        if forFeedSource == .User {
            self.notifyFeedsDeleted(feedKeys)
        } else {
            self.notifyRegioFeedsDeleted(feedKeys)
        }
    }

    func removeFeeds(_ feedEntities: [FeedEntity], forFeedSource: FeedSource) {

        let feedKeys: [Int64] = self.extractFeedKeys(feedEntities)

        try! self.realm.write {
            self.realm.delete(feedEntities)
        }
        if forFeedSource == .User {
            self.notifyFeedsDeleted(feedKeys)
        } else {
            self.notifyRegioFeedsDeleted(feedKeys)
        }
    }

    func createPostFeed(_ feed: FeedEntity!) {

        DDLogVerbose("create Post Feed")

        let changedFeedKeys: [Int64] = [feed.feedKey]

        try? self.realm.write {

            var feedEntity = self.realm.create(FeedEntity.self)
            self.setValues(sourceFeed: feed, targetFeed: &feedEntity)
            DDLogVerbose("Stored post feed to database: \(feedEntity)")
        }

        self.notifyFeedsChanged(changedFeedKeys)
    }

    func clearInOperation(_ realmInWriteTransaction: Realm) throws -> () -> Void {

        if (!realmInWriteTransaction.isInWriteTransaction) {
            throw StoreError.TransactionRequired
        }

        var deletedKeys = [Int64]()

        let feedEntities: [FeedEntity] = realmInWriteTransaction.objects(FeedEntity.self).toArray()

        deletedKeys = extractFeedKeys(feedEntities)

        realmInWriteTransaction.delete(feedEntities)

        let storedFeedUsers: [UserEntity] = realmInWriteTransaction.objects(UserEntity.self).toArray()
        realmInWriteTransaction.delete(storedFeedUsers)

        let storedFeedVisitors: [ProfileVisitorEntity] = self.realm.objects(ProfileVisitorEntity.self).toArray()
        realmInWriteTransaction.delete(storedFeedVisitors)

        let storedFeedEvents: [FeedEventEntity] = self.realm.objects(FeedEventEntity.self).toArray()
        realmInWriteTransaction.delete(storedFeedEvents)

        let storedFeedPhotos: [FeedPhotoEntity] = self.realm.objects(FeedPhotoEntity.self).toArray()
        realmInWriteTransaction.delete(storedFeedPhotos)

        let returnBlock: (() -> Void) = deletedKeys.isEmpty ? {
                } : {
            self.notifyFeedsDeleted(deletedKeys)
                }
        return returnBlock
    }

    func updateFeedLikeOrCommentCount(_ forFeedKey: Int64, forFeedSource: FeedSource, forLike: Bool, forComment: Bool) {

        try? self.realm.write {

            let savedFeed = self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "feedKey == %lld", forFeedKey)).first
            if let saved = savedFeed {

                if forLike {
                    let complimentCount = saved.complimentCount.value ?? 0
                    saved.complimentCount.value = complimentCount + 1
                    DDLogVerbose("Feed like count updated: \(saved)")
                } else if forComment {
                    let commentCount = saved.commentCount.value ?? 0
                    saved.commentCount.value = commentCount + 1
                    DDLogVerbose("Feed comment count updated: \(saved)")
                }
            }
        }

        if forFeedSource == .User {
            self.notifyFeedsChanged([forFeedKey])
        } else {
            self.notifyRegioFeedsChanged([forFeedKey])
        }
    }

    func updateCommentCountForFeed(_ forFeedKey: Int64, forFeedSource: FeedSource, increment: Bool) {

        try? self.realm.write {
            let savedFeed = self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "feedKey == %lld", forFeedKey)).first
            if let saved = savedFeed {
                let commentCount = saved.commentCount.value ?? 0

                if increment {
                    saved.commentCount.value = commentCount + 1
                } else {
                    if commentCount > 0 {
                        saved.commentCount.value = commentCount - 1
                    }
                }
                DDLogVerbose("Feed comments updated: \(saved)")
            }
        }

        if forFeedSource == .User {
            self.notifyFeedsChanged([forFeedKey])
        } else {
            self.notifyRegioFeedsChanged([forFeedKey])
        }
    }

    func createOrUpdateFeeds(_ feeds: [FeedEntity]!, forFeedSource: [FeedSource], users: [UserEntity]? = nil, visitors: [ProfileVisitorEntity]? = nil, events: [FeedEventEntity]? = nil, photos: [FeedPhotoEntity]? = nil, dropAllOther: Bool = false, silentUpdate: Bool = false) throws {

        DDLogVerbose("createOrUpdateFeeds with \(feeds.count) feeds")

        var changedFeedKeys: [Int64] = []
        var removedFeedKeys = Set<Int64>()

        try self.realm.write {

            if (dropAllOther && !silentUpdate) {
                let storedFeeds: [FeedEntity]? = self.getAllFeeds(forFeedSource)
                if let storedFeeds = storedFeeds {
                    _ = self.extractFeedKeys(storedFeeds).map({ removedFeedKeys.insert($0) })
                    self.realm.delete(storedFeeds)
                }

                if forFeedSource.contains(.User) {
                    let storedFeedVisitors: [ProfileVisitorEntity]? = self.realm.objects(ProfileVisitorEntity.self).toArray()
                    if let storedFeedVisitors = storedFeedVisitors {
                        self.realm.delete(storedFeedVisitors)
                    }
                }

                let storedFeedEvents: [FeedEventEntity]? = self.getAllFeedEvents(forFeedSource)
                if let storedFeedEvents = storedFeedEvents {
                    self.realm.delete(storedFeedEvents)
                }

                let storedFeedPhotos: [FeedPhotoEntity]? = self.getAllFeedPhotos(forFeedSource)
                if let storedFeedPhotos = storedFeedPhotos {
                    self.realm.delete(storedFeedPhotos)
                }
            }

            let lastFeedCreateTime = self.getNewestFeed()?.createTime.value

            for feed: FeedEntity in feeds {

                changedFeedKeys.append(feed.feedKey)
                removedFeedKeys.remove(feed.feedKey)

                let savedFeed = self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "feedKey == %lld", feed.feedKey)).first

                if var saved = savedFeed {
                    self.setValues(sourceFeed: feed, targetFeed: &saved)
                    DDLogVerbose("Feed updated : \(saved)")
                } else {
                    var feedEntity = self.realm.create(FeedEntity.self)
                    self.setValues(sourceFeed: feed, targetFeed: &feedEntity, dropAllOther: dropAllOther)

                    if let lastFeedCreateTime = lastFeedCreateTime,
                       let feedCreateTime = feed.createTime.value {
                        feedEntity.seen = (feedCreateTime < lastFeedCreateTime)
                    }

                    DDLogVerbose("Stored feed to database: \(feedEntity)")
                }
            }

            if let users = users {
                for user: UserEntity in users {

                    var savedFeedUser: UserEntity?

                    if let anonymousUserId = user.anonymousUserId {
                        savedFeedUser = self.realm.objects(UserEntity.self).filter(NSPredicate(format: "anonymousUserId == %@", anonymousUserId)).first
                    } else {
                        savedFeedUser = self.realm.objects(UserEntity.self).filter(NSPredicate(format: "id == %i", user.id)).first
                    }

                    if var savedFeedUser = savedFeedUser {
                        self.setFeedUserValues(sourceFeedUser: user, targetFeedUser: &savedFeedUser)
                        DDLogVerbose("Feed User updated : \(savedFeedUser)")
                    } else {
                        var feedUserEntity = self.realm.create(UserEntity.self)
                        self.setFeedUserValues(sourceFeedUser: user, targetFeedUser: &feedUserEntity)
                        DDLogVerbose("Stored feed user to database: \(feedUserEntity)")
                    }
                }
            }

            if let visitors = visitors, !forFeedSource.contains(.Region) {
                for visitor: ProfileVisitorEntity in visitors {

                    var arrPred = [NSPredicate(format: "feedKey == %lld", visitor.feedKey)]

                    if let userId = visitor.userId.value {
                        arrPred.append(NSPredicate(format: "userId == %i", userId))
                    } else if let anonymousUserId = visitor.anonymousUserId {
                        arrPred.append(NSPredicate(format: "anonymousUserId == %@", anonymousUserId))
                    }

                    let compoundPred: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: arrPred)

                    let savedProfileVisitor = self.realm.objects(ProfileVisitorEntity.self).filter(compoundPred).first

                    if var savedProfileVisitor = savedProfileVisitor {
                        self.setFeedProfileVisitorValues(sourceProfileVisitor: visitor, targetProfileVisitor: &savedProfileVisitor)
                        DDLogVerbose("Profile visitor updated : \(savedProfileVisitor)")
                    } else {
                        var profileVisitorEntity = self.realm.create(ProfileVisitorEntity.self)
                        self.setFeedProfileVisitorValues(sourceProfileVisitor: visitor, targetProfileVisitor: &profileVisitorEntity)
                        DDLogVerbose("Stored profile visitor to database: \(profileVisitorEntity)")
                    }
                }
            }

            if let events = events {
                for event: FeedEventEntity in events {
                    let savedFeedEvent = self.realm.objects(FeedEventEntity.self).filter(NSPredicate(format: "feedKey == %lld", event.feedKey)).first

                    if var savedFeedEvent = savedFeedEvent {
                        self.setFeedEventValues(sourceEvent: event, targetFeedEvent: &savedFeedEvent)
                        DDLogVerbose("Feed event updated : \(savedFeedEvent)")
                    } else {
                        var feedEventEntity = self.realm.create(FeedEventEntity.self)
                        self.setFeedEventValues(sourceEvent: event, targetFeedEvent: &feedEventEntity)
                        DDLogVerbose("Stored feed event to database: \(feedEventEntity)")
                    }
                }
            }

            if let photos = photos {
                for photo: FeedPhotoEntity in photos {

                    let arrPred = [
                        NSPredicate(format: "mediaTargetId == %i", photo.mediaTargetId),
                        NSPredicate(format: "feedKey == %lld", photo.feedKey)]

                    let compoundPred: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: arrPred)

                    let savedFeedPhoto = self.realm.objects(FeedPhotoEntity.self).filter(compoundPred).first

                    if var savedFeedPhoto = savedFeedPhoto {
                        self.setFeedPhotoValues(sourceFeedPhoto: photo, targetFeedPhoto: &savedFeedPhoto)
                        DDLogVerbose("Feed photo updated : \(savedFeedPhoto)")
                    } else {
                        var feedPhotoEntity = self.realm.create(FeedPhotoEntity.self)
                        self.setFeedPhotoValues(sourceFeedPhoto: photo, targetFeedPhoto: &feedPhotoEntity)
                        DDLogVerbose("Stored feed photo to database: \(feedPhotoEntity)")
                    }
                }
            }
        }

        if forFeedSource.contains(.Region) {
            self.notifyRegioFeedsDeleted(Array(removedFeedKeys))
            self.notifyRegioFeedsChanged(changedFeedKeys)
        } else {
            self.notifyFeedsDeleted(Array(removedFeedKeys))
            self.notifyFeedsChanged(changedFeedKeys)
        }
    }

    func getUnseenFeedCount() -> Int {
        return self.getUnseenFeeds().count
    }

    func getUnseenFeeds() -> [FeedEntity] {
        return self.realm.objects(FeedEntity.self).filter(NSPredicate(format: "internalFeedSource == %@ AND seen == 0", FeedSource.User.rawValue)).toArray()
    }

    func markAllFeedsSeen() {

        try? self.realm.write {

            let feeds = self.getUnseenFeeds()

            for feed in feeds where (feed.seen == false) {
                feed.seen = true
            }
        }
    }

    // MARK: - Private Helpers

    private func feedSourcesAsString(forFeedSource: [FeedSource]) -> [String] {

        let sourcesAsStrings = forFeedSource.map { (source: FeedSource) -> String in
            return source.rawValue
        }
        return sourcesAsStrings
    }

    private func extractFeedKeys(_ feedEntities: [FeedEntity]) -> [Int64] {
        return feedEntities.map({ $0.feedKey })
    }

    private func notifyFeedsChanged(_ feedKeys: [Int64]? = nil) {

        for wrapper in dashboardStoreObservers.values {
            wrapper.observer?.onFeedsChanged(feedKeys)
        }
    }

    private func notifyFeedsDeleted(_ feedKeys: [Int64]) {

        for wrapper in dashboardStoreObservers.values {
            wrapper.observer?.onFeedsDeleted(feedKeys)
        }
    }

    private func notifyRegioFeedsChanged(_ feedKeys: [Int64]? = nil) {

        for wrapper in dashboardStoreObservers.values {
            wrapper.observer?.onRegioFeedsChanged(feedKeys)
        }
    }

    private func notifyRegioFeedsDeleted(_ feedKeys: [Int64]) {

        for wrapper in dashboardStoreObservers.values {
            wrapper.observer?.onRegioFeedsDeleted(feedKeys)
        }
    }

    private func setValues(sourceFeed: FeedEntity, targetFeed: inout FeedEntity, dropAllOther: Bool = false) {

        targetFeed.feedKey = sourceFeed.feedKey
        targetFeed.commentCount.value = sourceFeed.commentCount.value
        targetFeed.complimentCount.value = sourceFeed.complimentCount.value
        targetFeed.content = sourceFeed.content
        targetFeed.feedSource = sourceFeed.feedSource
        targetFeed.feedType = sourceFeed.feedType
        targetFeed.isEditable = sourceFeed.isEditable
        targetFeed.isApproved = sourceFeed.isApproved
        targetFeed.headline = sourceFeed.headline
        targetFeed.isMediaRejected = sourceFeed.isMediaRejected
        targetFeed.userId.value = sourceFeed.userId.value
        targetFeed.createTime.value = sourceFeed.createTime.value
        targetFeed.mediaTargetId.value = sourceFeed.mediaTargetId.value
        targetFeed.mediaTargetUri = sourceFeed.mediaTargetUri
        targetFeed.mediaTargetUriPixel = sourceFeed.mediaTargetUriPixel
        targetFeed.mediaTargetType = sourceFeed.mediaTargetType
        targetFeed.commentRelatedObjectId.value = sourceFeed.commentRelatedObjectId.value
        targetFeed.complimentRelatedObjectId.value = sourceFeed.complimentRelatedObjectId.value
        targetFeed.visibility = sourceFeed.visibility
        targetFeed.commentMediaType = sourceFeed.commentMediaType
        targetFeed.complimentMediaType = sourceFeed.complimentMediaType
        targetFeed.message = sourceFeed.message
        targetFeed.motto = sourceFeed.motto
        targetFeed.groupName = sourceFeed.groupName
        targetFeed.firstMediaTargetId.value = sourceFeed.firstMediaTargetId.value
        targetFeed.isPixelated = sourceFeed.isPixelated
        targetFeed.galleryId.value = sourceFeed.galleryId.value
    }

    private func setFeedUserValues(sourceFeedUser: UserEntity, targetFeedUser: inout UserEntity) {

        targetFeedUser.id = sourceFeedUser.id
        targetFeedUser.anonymousUserId = sourceFeedUser.anonymousUserId
        targetFeedUser.avatarLarge = sourceFeedUser.avatarLarge
        targetFeedUser.avatarSmall = sourceFeedUser.avatarSmall
        targetFeedUser.isPixelated = sourceFeedUser.isPixelated
        targetFeedUser.gender = sourceFeedUser.gender
        targetFeedUser.username = sourceFeedUser.username
        targetFeedUser.subgender = sourceFeedUser.subgender
        targetFeedUser.isNew = sourceFeedUser.isNew
        targetFeedUser.residence = sourceFeedUser.residence
        targetFeedUser.residenceShort = sourceFeedUser.residenceShort
        targetFeedUser.userAge.value = sourceFeedUser.userAge.value
        targetFeedUser.partnerAge.value = sourceFeedUser.partnerAge.value
        targetFeedUser.distance = sourceFeedUser.distance
        targetFeedUser.verifiedState = sourceFeedUser.verifiedState
        targetFeedUser.onlineState = sourceFeedUser.onlineState
        targetFeedUser.isDisabled = sourceFeedUser.isDisabled
        targetFeedUser.type = sourceFeedUser.type
        targetFeedUser.subtype = sourceFeedUser.subtype

        if targetFeedUser.id > 0 {
            if let user = getContactForUserId(targetFeedUser.id) {
                targetFeedUser.friendshipState = user.friendshipState
            }
        }
    }

    private func getContactForUserId(_ userId: Int) -> UserEntity? {
        return self.realm.objects(UserEntity.self).filter(NSPredicate(format: "id == %d", userId)).first
    }

    private func setFeedProfileVisitorValues(sourceProfileVisitor: ProfileVisitorEntity, targetProfileVisitor: inout ProfileVisitorEntity) {

        targetProfileVisitor.userId.value = sourceProfileVisitor.userId.value
        targetProfileVisitor.anonymousUserId = sourceProfileVisitor.anonymousUserId
        targetProfileVisitor.visitTime = sourceProfileVisitor.visitTime
        targetProfileVisitor.isNew = sourceProfileVisitor.isNew
        targetProfileVisitor.feedKey = sourceProfileVisitor.feedKey
        targetProfileVisitor.parentFeedKey = sourceProfileVisitor.parentFeedKey
        targetProfileVisitor.commentMediaType = sourceProfileVisitor.commentMediaType
        targetProfileVisitor.complimentMediaType = sourceProfileVisitor.complimentMediaType
        targetProfileVisitor.createTime.value = sourceProfileVisitor.createTime.value
    }

    private func setFeedEventValues(sourceEvent: FeedEventEntity, targetFeedEvent: inout FeedEventEntity) {

        targetFeedEvent.feedKey = sourceEvent.feedKey
        targetFeedEvent.parentFeedKey = sourceEvent.parentFeedKey
        targetFeedEvent.eventName = sourceEvent.eventName
        targetFeedEvent.eventTime = sourceEvent.eventTime
        targetFeedEvent.locationCity = sourceEvent.locationCity
        targetFeedEvent.locationName = sourceEvent.locationName
        targetFeedEvent.userId.value = sourceEvent.userId.value
        targetFeedEvent.createTime.value = sourceEvent.createTime.value
        targetFeedEvent.eventImgUri = sourceEvent.eventImgUri
        targetFeedEvent.feedSource = sourceEvent.feedSource
        targetFeedEvent.commentCount.value = sourceEvent.commentCount.value
        targetFeedEvent.complimentCount.value = sourceEvent.complimentCount.value
        targetFeedEvent.commentMediaType = sourceEvent.commentMediaType
        targetFeedEvent.complimentMediaType = sourceEvent.complimentMediaType
        targetFeedEvent.commentRelatedObjectId.value = sourceEvent.commentRelatedObjectId.value
        targetFeedEvent.complimentRelatedObjectId.value = sourceEvent.complimentRelatedObjectId.value
        targetFeedEvent.feedType = sourceEvent.feedType
    }

    private func setFeedPhotoValues(sourceFeedPhoto: FeedPhotoEntity, targetFeedPhoto: inout FeedPhotoEntity) {

        targetFeedPhoto.mediaTargetId = sourceFeedPhoto.mediaTargetId
        targetFeedPhoto.mediaTargetCreateTime.value = sourceFeedPhoto.mediaTargetCreateTime.value
        targetFeedPhoto.mediaTargetUserId.value = sourceFeedPhoto.mediaTargetUserId.value
        targetFeedPhoto.mediaTargetUri = sourceFeedPhoto.mediaTargetUri
        targetFeedPhoto.mediaTargetType = sourceFeedPhoto.mediaTargetType
        targetFeedPhoto.isPixelated = sourceFeedPhoto.isPixelated
        targetFeedPhoto.galleryId = sourceFeedPhoto.galleryId
        targetFeedPhoto.feedKey = sourceFeedPhoto.feedKey
        targetFeedPhoto.feedSource = sourceFeedPhoto.feedSource
        targetFeedPhoto.parentFeedKey = sourceFeedPhoto.parentFeedKey
        targetFeedPhoto.commentCount.value = sourceFeedPhoto.commentCount.value
        targetFeedPhoto.complimentCount.value = sourceFeedPhoto.complimentCount.value
        targetFeedPhoto.commentMediaType = sourceFeedPhoto.commentMediaType
        targetFeedPhoto.complimentMediaType = sourceFeedPhoto.complimentMediaType
        targetFeedPhoto.complimentRelatedObjectId.value = sourceFeedPhoto.complimentRelatedObjectId.value
        targetFeedPhoto.commentRelatedObjectId.value = sourceFeedPhoto.commentRelatedObjectId.value
        targetFeedPhoto.createTime.value = sourceFeedPhoto.createTime.value
        targetFeedPhoto.userId.value = sourceFeedPhoto.userId.value
        targetFeedPhoto.feedType = sourceFeedPhoto.feedType
        targetFeedPhoto.feedGallerySpecialType = sourceFeedPhoto.feedGallerySpecialType
    }
}
