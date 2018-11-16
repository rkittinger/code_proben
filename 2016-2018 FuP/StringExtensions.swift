//
//  StringExtensions.swift
//
//  Created by Randy Kittinger on 08.03.16.
//  Copyright © 2016 F&P GmbH. All rights reserved.
//

import Foundation

extension String {

    var stringByDecodingHTMLEntities: String {

        var reformattedString = self
        Constant.HTMLXMLEntity.characterEntities.forEach { (key: String, value: Character) in
            reformattedString = reformattedString.replacingOccurrences(of: key, with: String(value))
        }

        return reformattedString
    }

    var isUsernameValid: Bool {
        do {
            let regex = try NSRegularExpression(pattern: Constant.Regex.usernameValidationPattern, options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count)) != nil
        } catch {
            return false
        }
    }

    var isEmailValid: Bool {
        do {
            let regex = try NSRegularExpression(pattern: Constant.Regex.emailValidationPattern, options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count)) != nil
        } catch {
            return false
        }
    }

    var hasYoutubeLinkAndThumbnail: (exists: Bool, thumbnailURL: String?, linkUrl: String?, textToPost: String?) {
        do {
            let regex = try NSRegularExpression(pattern: Constant.Regex.youtubeURLPattern, options: .caseInsensitive)

            var textToPost = clear(string: self)

            let matches = regex.matches(in: textToPost, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: textToPost.utf16.count))

            if let match = matches.first {

                let range = match.range
                let stringToMatch = textToPost as NSString

                // youtube URL
                let matchString = stringToMatch.substring(with: range)

                let subStringArrays = textToPost.components(separatedBy: matchString)

                // don't show youtube URL if it's alone or if there's one and it's on end of sentence
                if ((subStringArrays.last?.isEmpty == true && subStringArrays.first?.isEmpty == false) || matchString == textToPost), let range = textToPost.range(of: matchString) {
                    textToPost.replaceSubrange(range, with: "")
                }

                // extract videoId for preview image URL
                if let videoId = extractVideoIdFromLink(link: matchString) {
                    let thumbUrl = generateYouTubeThumbnailURL(fromVideoId: videoId)

                    let fullLinkURL = matchString.hasHttpsProtocol ? matchString : "https://\(matchString)"
                    return (true, thumbUrl, fullLinkURL, textToPost)
                }
            }
            return (false, nil, nil, textToPost)

        } catch {
            return (false, nil, nil, self)
        }
    }

    func extractVideoIdFromLink(link: String) -> String? {

        let pattern = Constant.Regex.videoIdPattern
        guard let regExp = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let options = NSRegularExpression.MatchingOptions(rawValue: 0)
        let range = NSRange(location: 0, length: link.count)
        let matches = regExp.matches(in: link, options: options, range: range)
        if let firstMatch = matches.first {
            let nsLink = link as NSString

            // trim the video-id to 11 characters (like YouTube does). We must do this manually for the thumbnail.
            return nsLink.substring(with: firstMatch.range).trim(max: 11)
        }
        return nil
    }

    func generateYouTubeThumbnailURL(fromVideoId videoId: String) -> String {
        return String(format: Constant.URL.youtubeThumbnailURL, videoId)
    }

    func containsDigits() -> Bool {

        let numbersRange = self.rangeOfCharacter(from: .decimalDigits)
        return numbersRange != nil
    }

    var couldContainSmileyAlias: Bool {
        do {
            let regex = try NSRegularExpression(pattern: Constant.Regex.smileyAliasPattern, options: [])
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count)) != nil
        } catch {
            return false
        }
    }

    var couldContainSmileyName: Bool {

        do {
            let regex = try NSRegularExpression(pattern: Constant.Regex.smileyNamePattern, options: [])
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count)) != nil
        } catch {
            return false
        }
    }

    var hasHttpsProtocol: Bool {
        return self.range(of: "https://") != nil
    }

    var localized: String {

        let path = Bundle.main.path(forResource: APIConstant.localizedCode, ofType: "lproj")
        let bundle = Bundle(path: path!)

        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }

    // careful, only works for one parameter
    func localized(_ text: String) -> String {
        return String.localizedStringWithFormat(NSLocalizedString(self, comment: ""), text)
    }

    var parseJSONString: Any? {

        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)

        if let jsonData = data {
            // Will return an object or nil if JSON decoding fails
            return try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
        } else {
            // Lossless conversion of the string was not possible
            return nil
        }
    }

    func separateWindowsHardReturnsAndHidden() -> String {
        return self.replacingOccurrences(of: "\\r\\n\n", with: " \n")
    }

    func separateWindowsHardReturns() -> String {
        return self.replacingOccurrences(of: "\r\n", with: " \n")
    }

    func separateMacHardReturns() -> String {
        return self.replacingOccurrences(of: "\n", with: " \n")
    }

    func containsMacHardReturn() -> Bool {
        return self == "\n"
    }

    /// pre-parsing, remove artifacts from API we don't want
    func clear(string: String!) -> String {

        let wordsWithSeparatedHardBreaksAndHidden = string.separateWindowsHardReturnsAndHidden()
        let wordsWithSeparatedHardBreaks = wordsWithSeparatedHardBreaksAndHidden.separateWindowsHardReturns()
        let wordsWithMacHardBreaks = wordsWithSeparatedHardBreaks.separateMacHardReturns()
        return wordsWithMacHardBreaks.replacingOccurrences(of: "\\", with: "")
    }

    func words() -> [String] {
        return self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
    }

    // MARK: Indexing
    func trim(max: Int) -> String {

        let textSize = self.count
        let index1: String.Index = self.index(self.startIndex, offsetBy: min(max, textSize))
        return String(self[..<index1])
    }

    func index(of string: String, options: String.CompareOptions = .literal) -> String.Index? {
        return range(of: string, options: options)?.lowerBound
    }

    func indices(of string: String, options: String.CompareOptions = .literal) -> [String.Index] {

        var result: [String.Index] = []
        var start = startIndex

        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }

    func ranges(of string: String, options: String.CompareOptions = .literal) -> [Range<String.Index>] {

        var result: [Range<String.Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }

    func birthdayIsAvailable() -> Bool {
        return self != Constant.Birthday.datePlaceholder && !self.isEmpty
    }

    func extractPrefix(withOffSet offset: Int) -> String {
        return String(self.prefix(offset))
    }
}

// MARK: - Regex

extension String {

    func capturedGroups(withRegex pattern: String) -> [String]? {
        var results = [String]()

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }

        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))

        guard let match = matches.first else {
            return results
        }

        let lastRangeIndex = match.numberOfRanges - 1

        guard lastRangeIndex >= 1 else {
            return results
        }

        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)

            if (capturedGroupIndex.location + capturedGroupIndex.length > self.count) {
                continue
            }
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)

            if !matchedString.isEmpty {
                results.append(matchedString)
            }
        }

        return results.isEmpty ? nil : results
    }
}
