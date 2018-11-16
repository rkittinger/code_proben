//
//  JCAppApi+Dashboard.swift
//
//  Created by Randy Kittinger on 09.09.16.
//  Copyright © 2016 F&P GmbH. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import CocoaLumberjack

extension JcAppApi {

    func getFeedList(_ limit: Int? = 30,
                     lastFeedKey: Int64? = nil,
                     onCompletion: @escaping (FeedListResponse?, JCAppApiError?) -> Void) {

        let params: Parameters = (lastFeedKey == nil) ? ["limit": limit!] : ["limit": limit!, "last_feed_key": NSNumber(value: lastFeedKey!)]
        let getFeedListType = APIConstant.EndPoint.Dashboard.getFeedList

        get(getFeedListType.path(), parameters: params, errorAnalyticsEvent: getFeedListType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            if error?.statusCode == 404 {
                DDLogDebug("mocking data...")

                self.getMockData("feed-list", completion: onCompletion)

            } else {
                ObjectSerializer<FeedListResponse>(onCompletion).serialize(request, error: error)
            }
        }
    }

    func getRegioFeedList(_ limit: Int = 10,
                          lastFeedKey: Int64? = nil,
                          lon: Float? = nil,
                          lat: Float? = nil,
                          onCompletion: @escaping (FeedListResponse?, JCAppApiError?) -> Void) {

        var params = Parameters()
        params["limit"] = limit
        if let lastFeedKey = lastFeedKey {
            params["last_feed_key"] = lastFeedKey
        }
        if let lon = lon, let lat = lat {
            params["lon"] = lon
            params["lat"] = lat
        }

        let getRegioFeedListType = APIConstant.EndPoint.Dashboard.getRegioFeedList

        get(getRegioFeedListType.path(), parameters: params, errorAnalyticsEvent: getRegioFeedListType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            DDLogDebug("Retrieving Regio Feeds from Server...")
            ObjectSerializer<FeedListResponse>(onCompletion).serialize(request, error: error)
        }
    }

    func getFeedDetailFromNotificaton(_ statusmsgId: Int, onCompletion: @escaping (FeedListResponse?, JCAppApiError?) -> Void) {

        let getFeedDetailFromNotificatonType = APIConstant.EndPoint.Dashboard.getFeedDetailFromNotificaton
        let endPoint = String(format: getFeedDetailFromNotificatonType.path(), statusmsgId)

        get(endPoint, errorAnalyticsEvent: getFeedDetailFromNotificatonType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            DDLogDebug("Retrieving Feed Detail in Bell Notification from Server...")
            ObjectSerializer<FeedListResponse>(onCompletion).serialize(request, error: error)
        }
    }

    func getFeedDetail(_ feedItemId: Int64, onCompletion: @escaping (FeedListResponse?, JCAppApiError?) -> Void) {

        let getFeedDetailType = APIConstant.EndPoint.Dashboard.getFeedDetail
        let endPoint = String(format: getFeedDetailType.path(), String(feedItemId))

        get(endPoint, errorAnalyticsEvent: getFeedDetailType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            DDLogDebug("Retrieving Feed Detail from Server...")
            ObjectSerializer<FeedListResponse>(onCompletion).serialize(request, error: error)
        }
    }

    func getRegioFeedDetail(_ feedItemId: Int64, userId: Int, onCompletion: @escaping (FeedListResponse?, JCAppApiError?) -> Void) {

        let getRegioFeedDetailType = APIConstant.EndPoint.Dashboard.getRegioFeedDetail
        let endPoint = String(format: getRegioFeedDetailType.path(), userId, String(feedItemId))

        get(endPoint, errorAnalyticsEvent: getRegioFeedDetailType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            DDLogDebug("Retrieving Feed Detail from Server...")
            ObjectSerializer<FeedListResponse>(onCompletion).serialize(request, error: error)
        }
    }

    func likeFeed(_ complimentMediaType: String, itemId: Int64, userId: Int, onCompletion: @escaping (Bool, JCAppApiError?) -> Void) {

        let likeFeedType = APIConstant.EndPoint.Dashboard.likeFeed
        let endPoint = String(format: likeFeedType.path(), complimentMediaType, String(itemId))

        put(endPoint, parameters: ["user_id": userId], encoding: JSONEncoding.default, errorAnalyticsEvent: likeFeedType.firebaseErrorEvent(), completion: { (request: DataRequest, error: JCAppApiError?) in

            if request.response?.statusCode == 204 {
                onCompletion(true, nil)
            } else {
                onCompletion(false, error)
            }
        })
    }

    func deleteFeed(_ feedType: FeedType, feedItemIdList: [Int64], completion: @escaping (Bool, JCAppApiError?) -> Void) {

        let stringWithCommas = (feedItemIdList as NSArray).componentsJoined(by: ",")
        let deleteFeedType = APIConstant.EndPoint.Dashboard.deleteFeed
        let endPoint = String(format: deleteFeedType.path(), feedType.rawValue, stringWithCommas)

        delete(endPoint, errorAnalyticsEvent: deleteFeedType.firebaseErrorEvent()) { (_: DataRequest, error: JCAppApiError?) in
            completion(error == nil, error)
        }
    }

    func deleteComment(_ commentMediaType: String, commentId: Int, completion: @escaping (Bool, JCAppApiError?) -> Void) {

        let deleteCommentType = APIConstant.EndPoint.Dashboard.deleteComment
        let endPoint = String(format: deleteCommentType.path(), commentMediaType, commentId)

        delete(endPoint, errorAnalyticsEvent: deleteCommentType.firebaseErrorEvent()) { (_: DataRequest, error: JCAppApiError?) in
            completion(error == nil, error)
        }
    }

    func postFeed(_ postFeedBody: PostFeedRequestBody, completion: @escaping (Feed?, JCAppApiError?) -> Void) {

        let params = Mapper<PostFeedRequestBody>().toJSON(postFeedBody)
        let postFeedType = APIConstant.EndPoint.Dashboard.postFeed

        post(postFeedType.path(), parameters: params, encoding: JSONEncoding.default, errorAnalyticsEvent: postFeedType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            ObjectSerializer<Feed>(completion).serialize(request, error: error)
        }
    }

    func postComment(_ commentMediaType: String, mediaItemId: Int64, content: String, mediaUserId: Int, completion: @escaping (Comment?, JCAppApiError?) -> Void) {

        let postCommentType = APIConstant.EndPoint.Dashboard.postComment
        let endPoint = String(format: postCommentType.path(), commentMediaType, mediaItemId)

        post(endPoint, parameters: ["content": content, "media_user_id": mediaUserId], encoding: JSONEncoding.default, errorAnalyticsEvent: postCommentType.firebaseErrorEvent()) { (request: DataRequest, error: JCAppApiError?) in

            ObjectSerializer<Comment>(completion).serialize(request, error: error)
        }
    }

    private func getMockData(_ fromFile: String, completion: @escaping (FeedListResponse?, JCAppApiError?) -> Void) {

        if let path = Bundle.main.path(forResource: fromFile, ofType: "json") {
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                do {
                    let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                    let feedListResponse: FeedListResponse = Mapper<FeedListResponse>().map(JSON: jsonResult as! [String: Any])!
                    completion(feedListResponse, nil)

                } catch {
                    DDLogDebug("Failed to parse JSON for \(fromFile).json")
                }
            } catch {
                DDLogDebug("Failed to process \(fromFile).json from file contents")
            }
        }
    }
}
