//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI
import UIKit

/// SwiftUI wrapper for displaying links in a text view.
struct LinkTextView: UIViewRepresentable {

    @Injected(\.utils) private var utils

    var message: ChatMessage
    var width: CGFloat
    var textColor: UIColor

    func makeUIView(context: Context) -> UITextView {
        let textView = OnlyLinkTappableTextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.dataDetectorTypes = .link
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.text = text
        textView.textColor = textColor
        textView.linkTextAttributes = utils.messageListConfig.messageDisplayOptions.messageLinkDisplayResolver(message)
        textView.setAccessibilityIdentifier()

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        DispatchQueue.main.async {
            let size = text.frameSize(maxWidth: width)
            uiView.frame.size = size
        }
    }

    private var text: String {
        message.adjustedText
    }
}

/// Text View that ignores all user interactions except touches on links

class OnlyLinkTappableTextView: UITextView, AccessibilityView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let range = characterRange(at: point),
           !range.isEmpty,
           let position = closestPosition(to: point, within: range),
           let styles = textStyling(at: position, in: .forward),
           styles[.link] != nil {
            if (containsMospacePattern(urlString: self.text) ?? false) {
                return nil
            }
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
    func containsMospacePattern(urlString: String) -> Bool {
        let regex = #"mospace\/\d+"#
        let range = NSRange(location: 0, length: urlString.utf16.count)
        let pattern = try! NSRegularExpression(pattern: regex)
        return pattern.firstMatch(in: urlString, options: [], range: range) != nil
    }
}

extension String {
    func frameSize(maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body)
        ]
        let attributedText = NSAttributedString(string: self, attributes: attributes)
        let width = maxWidth != nil ? min(maxWidth!, CGFloat.greatestFiniteMagnitude) : CGFloat.greatestFiniteMagnitude
        let height = maxHeight != nil ? min(maxHeight!, CGFloat.greatestFiniteMagnitude) : CGFloat.greatestFiniteMagnitude
        let constraintBox = CGSize(width: width, height: height)
        let rect = attributedText.boundingRect(
            with: constraintBox,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        .integral

        return rect.size
    }
}
