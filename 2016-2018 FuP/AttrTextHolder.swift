//
//  AttrTextHolder.swift
//
//  Created by Randy Kittinger on 14.02.17.
//  Copyright © 2017 F&P GmbH. All rights reserved.
//

import UIKit
import SwiftSoup
import SwinjectStoryboard
import CocoaLumberjack

class AttrTextHolder {

    private let linkDetector: NSDataDetector? = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    static let defaultSmileyPixelSize: Int = 60
    /// minimum height for smiley to use as fallback when there is no value for the line height
    private static let minSmileyPixelSize: CGFloat = 20.0

    private var lastAttributedString: NSMutableAttributedString?
    private var textAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.font: UIFont.proximaNovaSoft(), NSAttributedStringKey.foregroundColor: AppColors.whiteColor]
    var originalText: String = ""
    var font: UIFont?
    var respectLineHeight = false

    private var smileyAnimationEnabled: Bool = true
    private var customRespectLineHeight: CGFloat?
    private var fontLineHeight: CGFloat = minSmileyPixelSize

    private var maxSmileyHeight: Int {
        let lineHeight = self.customRespectLineHeight ?? (self.fontLineHeight * Constant.UI.scaleFontHeightGif)
        return self.respectLineHeight ? Int(lineHeight) : AttrTextHolder.defaultSmileyPixelSize
    }

    /// internal list of all added GifAttachments
    var gifAttachments: [GifAttachment] = []

    private weak var gifAttachmentDelegate: GifAttachmentDelegate?

    // handle A Tag
    private var handleATag = true

    var gifAnimator: GifAttachmentAnimator = GifAttachmentAnimator.shared

    private var smileyStore: SmileyStore? = SwinjectStoryboard.defaultContainer.resolve(SmileyStore.self)

    init(withDelegate delegate: GifAttachmentDelegate? = nil) {
        self.gifAttachmentDelegate = delegate
    }

    deinit {
        self.gifAnimator.remove(gifAttachments)
        self.gifAttachments.removeAll()
    }

    func setupView(respectLineForHeight: CGFloat? = nil, forFont: UIFont? = nil, forFontColor: UIColor? = nil, handleATag: Bool = true, centerAlignment: Bool = false, smileyAnimationEnabled: Bool = true) {

        self.smileyAnimationEnabled = smileyAnimationEnabled
        self.font = forFont
        self.fontLineHeight = forFont?.lineHeight ?? AttrTextHolder.minSmileyPixelSize
        self.respectLineHeight = (respectLineForHeight != nil)
        self.customRespectLineHeight = respectLineForHeight

        self.textAttributes = [NSAttributedStringKey.font: forFont ?? UIFont.proximaNovaSoft(), NSAttributedStringKey.foregroundColor: forFontColor ?? AppColors.whiteColor]

        if (centerAlignment == true) {
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            self.textAttributes[NSAttributedStringKey.paragraphStyle] = style
        }

        self.handleATag = handleATag
    }

    func buildAttributedText(_ text: String!, handleSmileys: Bool = true, handleATag: Bool = true, respectLineHeight: Bool = false, centerAlignment: Bool = false) -> NSAttributedString! {

        self.originalText = text
        self.respectLineHeight = respectLineHeight

        if let lastAttributedString = self.lastAttributedString {
            return lastAttributedString
        }

        var message = self.clear(string: text)

        let attributedString = NSMutableAttributedString()

        var currentIndex = message.startIndex
        let endIndex = message.endIndex

        var aTagRanges = message.ranges(of: "<a.*?>(.*?)</a>", options: .regularExpression)

        if handleATag == true {
            // handle with a href tags
            aTagRanges.forEach { (range: Range) in
                if (range.lowerBound > currentIndex) {
                    self.handleTextPart(attributedString, String(message[currentIndex..<range.lowerBound]), handleSmileys: handleSmileys, centerAlignment: centerAlignment)
                }

                self.handleATag(attributedString, String(message[range.lowerBound..<range.upperBound]), centerAlignment: centerAlignment)
                currentIndex = range.upperBound
            }
        }

        if (currentIndex < endIndex) {
            self.handleTextPart(attributedString, String(message[currentIndex..<endIndex]), handleSmileys: handleSmileys, centerAlignment: centerAlignment)
        }

        self.collectGifAttachmentRanges(for: attributedString)

        message = attributedString.stringByDecodingHTMLEntities.string
        aTagRanges = message.ranges(of: "<a.*?>(.*?)</a>", options: .regularExpression)

        // remove all the italic codecs from string and replace covered text with attributed italic text.
        let iTagRanges = message.ranges(of: "\\[i\\](.*?)\\[/i\\]", options: .regularExpression)
        let uTagRanges = message.ranges(of: "\\[u\\](.*?)\\[/u\\]", options: .regularExpression)
        let bTagRanges = message.ranges(of: "\\[b\\](.*?)\\[/b\\]", options: .regularExpression)

        // remove all the href links
        aTagRanges.forEach { (range: Range) in
            let nsRange = (message as NSString).range(of: String(message[range.lowerBound..<range.upperBound]))
            attributedString.removeAttribute(NSAttributedStringKey.link, range: nsRange)
            attributedString.addAttributes([NSAttributedStringKey.foregroundColor: AppColors.whiteColor], range: nsRange)
        }

        // remove all the bold codecs from string and replace covered text with attributed bold text.
        bTagRanges.forEach { (range: Range) in
            var nsRange = (message as NSString).range(of: String(message[(range.lowerBound)..<(range.upperBound)]))
            nsRange.location += "[b]".count
            nsRange.length -= ("[b]".count + "[/b]".count)

            if (nsRange.length > 0 && nsRange.location > 0) {
                attributedString.addAttributes([NSAttributedStringKey.font: UIFont.proximaNovaSoftBold()], range: nsRange)
            }
        }

        // remove all the underlined codecs from string and replace covered text with attributed underlined text.
        uTagRanges.forEach { (range: Range) in
            var nsRange = (message as NSString).range(of: String(message[(range.lowerBound)..<(range.upperBound)]))
            nsRange.location += "[u]".count
            nsRange.length -= ("[u]".count + "[/u]".count)

            if (nsRange.length > 0 && nsRange.location > 0) {
                attributedString.addAttributes([NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue], range: nsRange)
            }
        }

        iTagRanges.forEach { (range: Range) in
            var nsRange = (message as NSString).range(of: String(message[(range.lowerBound)..<(range.upperBound)]))
            nsRange.location += "[i]".count
            nsRange.length -= ("[i]".count + "[/i]".count)

            if (nsRange.length > 0 && nsRange.location > 0) {
                attributedString.addAttributes([NSAttributedStringKey.font: UIFont.proximaNovaSoftItalic()], range: nsRange)
            }
        }

        attributedString.removeCharactersForRegularExpression(regularExpression: "\\[b\\]|\\[/b\\]|\\[u\\]|\\[/u\\]|\\[i\\]|\\[/i\\]")

        if self.smileyAnimationEnabled {
            self.gifAnimator.add(self.gifAttachments)
        }

        return attributedString.stringByDecodingHTMLEntities
    }

    private func getRangeWhereLinkDetected(text: String) -> [NSTextCheckingResult] {
            return self.linkDetector?.matches(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.count)) ?? []
    }

    /// extracts links through detector and add them in the attributed text with styling attributes
    private func addLinkManually(for attributedString: NSMutableAttributedString) {

        if let linkMatches = self.linkDetector?.matches(in: attributedString.string, options: .reportProgress, range: NSRange(location: 0, length: attributedString.length)) {

            linkMatches.forEach { (linkMatch: NSTextCheckingResult) in

                if let _linkMatchURL = linkMatch.url {
                    let linkAttributes: [NSAttributedStringKey: Any] = [
                        NSAttributedStringKey.link: _linkMatchURL,
                        NSAttributedStringKey.font: UIFont.proximaNovaSoft()
                    ]

                    attributedString.setAttributes(linkAttributes, range: linkMatch.range)
                }
            }
        }
    }

    /// extracts all ranges for the gif attachments to invalidate each single gif attachment later on
    private func collectGifAttachmentRanges(for attributedString: NSAttributedString) {

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: [], using: { (dict: [NSAttributedStringKey: Any]?, range: NSRange!, _: UnsafeMutablePointer<ObjCBool>) -> Void in

            dict?.forEach { entry in
                if (entry.key.rawValue == "NSAttachment" && entry.value is NSTextAttachment) {
                    let attachment = (entry.value as! NSTextAttachment)
                    self.gifAttachments.filter({ $0.textAttachment == attachment }).first?.range = range
                }
            }

        })
    }

    private func handleATag(_ string: NSMutableAttributedString, _ aTagString: String, centerAlignment: Bool = false) {

        do {
            let document = try SwiftSoup.parse(aTagString)
            let aTagElements = try document.select("a")
            for aTagElement in aTagElements {

                if let href = aTagElement.getAttributes()?.get(key: "href") {

                    let linkText = try aTagElement.text()
                    let linkString = NSMutableAttributedString(string: linkText, attributes: [NSAttributedStringKey.font: UIFont.proximaNovaSoft()])
                    linkString.addAttribute(NSAttributedStringKey.link, value: href, range: NSRange(location: 0, length: linkText.utf16.count))

                    if (centerAlignment == true) {
                        let style = NSMutableParagraphStyle()
                        style.alignment = NSTextAlignment.center
                        linkString.addAttribute(NSAttributedStringKey.paragraphStyle, value: style, range: NSRange(location: 0, length: linkText.utf16.count))
                    }

                    string.append(linkString)
                }
            }

        } catch {
            DDLogError("Error parsing A tag \(aTagString)")
        }
    }

    private func handleTextPart(_ attributedString: NSMutableAttributedString, _ s: String, handleSmileys: Bool = true, centerAlignment: Bool = false) {

        let smileysAliasDictionary = self.smileyStore?.getSmileyAliasAndNames()

        if !handleSmileys {
            attributedString.append(NSAttributedString(string: s, attributes: self.textAttributes))
            return
        }

        let word = s.components(separatedBy: CharacterSet.whitespaces).filter { (isIncluded: String) -> Bool in
            !isIncluded.isEmpty
        }.joined(separator: " ")

        // Handle the state of the attributedString without encoding
        var textWithoutEncoding = String()
        var textCheckingResults = self.getRangeWhereLinkDetected(text: word)

        if s.first == " " {
            attributedString.append(NSAttributedString(string: " ", attributes: self.textAttributes))
        }

        if (word.couldContainSmileyAlias || word.couldContainSmileyName) {

            var usedSmileyAliasArray = self.getUsedAliasSorted(word: word, smileysAliasDictionary: smileysAliasDictionary)

            if usedSmileyAliasArray.isEmpty == false {
                let components = self.getWordAsArrayWithoutSmileys(word: word, usedSmileyAliasArray: usedSmileyAliasArray)

                for (componentIndex, currentComponent) in components.enumerated() {

                    attributedString.append(NSAttributedString(string: currentComponent, attributes: self.textAttributes))
                    textWithoutEncoding.append(currentComponent)

                    if (componentIndex < usedSmileyAliasArray.count) {
                        let smileyAliasName = usedSmileyAliasArray[componentIndex]
                        var isAliasPartOfLink = false

                        let nextElement = ((componentIndex + 1) < components.count ? (componentIndex + 1) : componentIndex)

                        // TOOD: Simplify the logic or better big parser refactoring :)
                        for (index, textCheckingResult) in textCheckingResults.enumerated() {
                            if (textCheckingResult.range.location <= (textWithoutEncoding.count - 1)
                                    && ((textCheckingResult.range.length + textCheckingResult.range.location) <= (textWithoutEncoding.count + components[nextElement].count + smileyAliasName.count))
                                    && textCheckingResult.range.length + textCheckingResult.range.location >= textWithoutEncoding.count - 1) {

                                textCheckingResults.remove(at: index)
                                isAliasPartOfLink = true
                                break
                            }
                        }

                        textWithoutEncoding.append(smileyAliasName)

                        if isAliasPartOfLink {
                            attributedString.append(NSAttributedString(string: smileyAliasName, attributes: self.textAttributes))
                        } else {
                            if let smileyName = smileysAliasDictionary?[smileyAliasName],
                               let gifImage = UIImage.gif(name: smileyName, maxHeight: self.maxSmileyHeight) {

                                let gifAttachment = GifAttachment(gifImage: gifImage, gifAttachmentDelegate: self.gifAttachmentDelegate)
                                gifAttachment.gifImageName = smileyName

                                attributedString.append(NSAttributedString(string: " ", attributes: self.textAttributes))
                                attributedString.append(NSAttributedString(attachment: gifAttachment.textAttachment))
                                gifAttachments.append(gifAttachment)
                            } else {
                                attributedString.append(NSAttributedString(string: " *\(smileyAliasName)*", attributes: self.textAttributes))
                            }

                            if (currentComponent.components(separatedBy: "\n").last?.isEmpty ?? false == false) {
                                attributedString.append(NSAttributedString(string: " ", attributes: self.textAttributes))
                                textWithoutEncoding.append(" ")
                            }
                        }
                    }
                }
            } else {
                var trimmedEmptySpaces = word + " "
                trimmedEmptySpaces = trimmedEmptySpaces.replacingOccurrences(of: "\n ", with: "\n")

                attributedString.append(NSAttributedString(string: trimmedEmptySpaces, attributes: self.textAttributes))
            }
        } else {
            var trimmedEmptySpaces = word + " "
            trimmedEmptySpaces = trimmedEmptySpaces.replacingOccurrences(of: "\n ", with: "\n")

            attributedString.append(NSAttributedString(string: trimmedEmptySpaces, attributes: self.textAttributes))
        }

        // add links
        self.getRangeWhereLinkDetected(text: attributedString.string).forEach { (textCheckingResult: NSTextCheckingResult) in
            if let _linkMatchURL = textCheckingResult.url {

                var linkAttributes: [NSAttributedStringKey: Any] = [
                    NSAttributedStringKey.link: _linkMatchURL,
                    NSAttributedStringKey.font: UIFont.proximaNovaSoft()
                ]

                if centerAlignment == true {
                    let style = NSMutableParagraphStyle()
                    style.alignment = NSTextAlignment.center
                    linkAttributes[NSAttributedStringKey.paragraphStyle] = style
                }

                attributedString.setAttributes(linkAttributes, range: textCheckingResult.range)
            }
        }
    }

    private func getUsedAliasSorted(word: String, smileysAliasDictionary: [String: String]?) -> [String] {

        var usedSmileyAliasDictionaryArray = [[Int: String]]()

        smileysAliasDictionary?.forEach({ (smileyAlias: String, _: String) in
            let ranges = word.ranges(of: smileyAlias)
            for range in ranges {

                let nsRange = NSRange.create(from: range, for: word)
                usedSmileyAliasDictionaryArray.append([nsRange.location: smileyAlias])
            }
        })

        usedSmileyAliasDictionaryArray = usedSmileyAliasDictionaryArray.sorted(by: { (leftDictionary: [Int: String], rightDictionary: [Int: String]) -> Bool in

            if let leftPosition = leftDictionary.first?.key,
               let rightPosition = rightDictionary.first?.key {
                return leftPosition < rightPosition
            } else {
                return true
            }
        })

        var usedSmileyArray = [String]()
        for usedSmileyAliasArray in usedSmileyAliasDictionaryArray {
            if let alias = usedSmileyAliasArray.first?.value {
                usedSmileyArray.append(alias)
            }
        }

        return usedSmileyArray
    }

    private func getWordAsArrayWithoutSmileys(word: String, usedSmileyAliasArray: [String]) -> [String] {

        guard let firstAlias = usedSmileyAliasArray.first else {
            return [String]()
        }

        var components = word.components(separatedBy: firstAlias)
        var currentIndex = 0

        while (currentIndex != components.count) {

            for foundedSmiley in usedSmileyAliasArray {
                let subcomponent = components[currentIndex].components(separatedBy: foundedSmiley)

                if (subcomponent.first != word) {
                    components.remove(at: currentIndex)

                    var subCurrentIndex = currentIndex
                    for sunbcompoent in subcomponent {
                        components.insert(sunbcompoent, at: subCurrentIndex)
                        subCurrentIndex += 1
                    }
                }
            }
            currentIndex += 1
        }
        return components
    }

/// pre-parsing, remove artifacts from API we don't want
    private func clear(string: String?) -> String {

        guard let text = string else {
            return ""
        }
        let wordsWithSeparatedHardBreaksAndHidden = text.separateWindowsHardReturnsAndHidden()
        let wordsWithSeparatedHardBreaks = wordsWithSeparatedHardBreaksAndHidden.separateWindowsHardReturns()
        let wordsWithMacHardBreaks = wordsWithSeparatedHardBreaks.separateMacHardReturns()
        return wordsWithMacHardBreaks.replacingOccurrences(of: "\\", with: "")
    }
}
