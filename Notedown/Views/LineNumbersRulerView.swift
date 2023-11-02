//
//  LineNumbersRulerView.swift
//  Notedown
//
//  Created by Bruno Philipe on 21/2/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//  Copyright © 2023 Gamunu Balagalla. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Cocoa

let kRulerMargin: CGFloat = 10.0

class LineNumbersRulerView: NSRulerView
{
	// MARK: - Initializers and Deinitializer

	override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation)
	{
		super.init(scrollView: scrollView, orientation: orientation)

		setupStateObservers()
	}

	required init(coder: NSCoder)
	{
		super.init(coder: coder)

		setupStateObservers()
	}

	deinit
	{
		clientView = nil
		NotificationCenter.default.removeObserver(self)
		Preferences.instance.removeObserver(self, forKeyPath: "lineNumbersFont")
		Preferences.instance.removeObserver(self, forKeyPath: "editorFont")
	}

	override var mouseDownCanMoveWindow: Bool
	{
		return true
	}

	var font = Preferences.instance.lineNumbersFont
	{
		didSet
		{
			invalidateHashMarks()
		}
	}

	var backgroundColor = #colorLiteral(red: 0.9688121676, green: 0.9688346982, blue: 0.9688225389, alpha: 1)
	{
		didSet
		{
			invalidateHashMarks()
			needsDisplay = true
		}
	}

	var textColor = #colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 1)
	{
		didSet
		{
			invalidateHashMarks()
			needsDisplay = true
		}
	}

	// MARK: - Notifications

	override func observeValue(forKeyPath keyPath: String?,
	                           of object: Any?,
	                           change: [NSKeyValueChangeKey : Any]?,
	                           context: UnsafeMutableRawPointer?)
	{
		if let keyPath = keyPath, ["lineNumbersFont", "editorFont"].contains(keyPath) && object is Preferences
		{
			let pref = Preferences.instance
			var font = pref.lineNumbersFont
			
			if font.pointSize > pref.editorFont.pointSize,
				let smallerFont = NSFont(descriptor: font.fontDescriptor, size: pref.editorFont.pointSize)
			{
				font = smallerFont
			}
			
			self.font = font
		}
	}

	@objc func textDidChange(notification: Notification)
	{
		needsDisplay = true
		needsLayout = true
	}

	@objc func scrollViewDidScroll(notification: Notification)
	{
		needsDisplay = true
	}

	// MARK: - Override Methods

	override var clientView: NSView?
	{
		didSet
		{
			NotificationCenter.default.removeObserver(self)

			if clientView == nil
			{
				return
			}

			if let textView = self.textView
			{
				NotificationCenter.default.addObserver(self,
				                                       selector: #selector(LineNumbersRulerView.textDidChange(notification:)),
				                                       name: NSTextStorage.didProcessEditingNotification,
				                                       object: textView.textStorage)
			}

			if let contentView = scrollView?.contentView
			{
				NotificationCenter.default.addObserver(self,
				                                       selector: #selector(LineNumbersRulerView.scrollViewDidScroll(notification:)),
				                                       name: NSView.boundsDidChangeNotification,
				                                       object: contentView)
			}
		}
	}

	override func drawHashMarksAndLabels(in rect: NSRect)
	{
		guard let textView				= textView,
			  let scrollView			= scrollView,
			  let textString: NSString	= textView.textStorage?.string as NSString?,
			  let layoutManager			= textView.layoutManager as? EditorLayoutManager,
			  let textContainer			= textView.textContainer,
			  let selectedRange			= textView.selectedRanges.first?.rangeValue
		else
		{
			return
		}

		backgroundColor.setFill()
		rect.fill()

		textColor.setStroke()

		let emptyText			= textString.length == 0
		let lastCharIndex		= emptyText ? 0 : textString.length - 1
		let lastCharIsNewLine	= emptyText ? false : textString.character(at: lastCharIndex) == unichar(0x0A)
		let boundsRect			= scrollView.contentView.bounds
		let heightInset			= textView.textContainerInset.height
		let visibleRect			= CGRect(x: boundsRect.origin.x, y: boundsRect.origin.y - heightInset,
		               			         width: boundsRect.size.width, height: boundsRect.size.height + heightInset * 2.0)
		let visibleRange		= layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
		let gutterWidth			= requiredThickness
		let topScrollOffset		= boundsRect.origin.y

		var columnRect: CGRect = .zero
		var lineNumber: UInt = 0

		layoutManager.enumerateLineFragments(forGlyphRange: visibleRange)
		{
			(rect, usedRect, textContainer, glyphRange, stop) in

			let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
			let paraRange = textString.paragraphRange(for: charRange)

			if charRange.location == paraRange.location
			{
				let gutterAttributes: [NSAttributedString.Key : Any]
				let intersectionRange = NSIntersectionRange(paraRange, selectedRange)

				if !(intersectionRange.location == 0 && intersectionRange.length == 0) // Normal intersection
					|| (paraRange.location == 0 && selectedRange.location == 0) // first char of first line
					|| ((NSMaxRange(paraRange) == selectedRange.location) && (selectedRange.location == lastCharIndex + 1) && !lastCharIsNewLine) // last char of last line (with other chars after the last \n)
				{
					gutterAttributes = self.selectedNumberTextAttributes
				}
				else
				{
					gutterAttributes = self.numberTextAttributes
				}

				columnRect = CGRect(x: 0, y: rect.origin.y + heightInset, width: gutterWidth - 8.0, height: rect.size.height)
				lineNumber = layoutManager.lineNumber(for: charRange) + 1

				let numberString = NSString(string: "\(lineNumber)")

				let size = numberString.size(withAttributes: gutterAttributes)
				let drawRect = columnRect.offsetBy(dx: 0, dy: (columnRect.height - size.height) / 2 - topScrollOffset)

				numberString.draw(in: drawRect, withAttributes: gutterAttributes)
			}

			// This information will be used to properly place the line number for the empty line special case below
			columnRect = columnRect.offsetBy(dx: 0, dy: rect.size.height)
		}

		// Special case: Draw line number for empty trailing lines and for the empty string text.
		if emptyText || lastCharIsNewLine
		{
			let gutterAttributes: [NSAttributedString.Key : Any]

			if NSMaxRange(selectedRange) > lastCharIndex || lastCharIndex == 0
			{
				gutterAttributes = selectedNumberTextAttributes
			}
			else
			{
				gutterAttributes = numberTextAttributes
			}

			let numberString = NSString(string: "\(lineNumber + 1)")
			let size = numberString.size(withAttributes: gutterAttributes)

			if emptyText
			{
				let font = (textView.font ?? Preferences.instance.editorFont)
				let normalSize = font.ascender - font.descender

				// Unfortunately AppKit is not returning a sane value for the following commented call, which should produce the
				// same height value as the height value of the `rect` parameter of the `enumerateLineFragments()` callback.
				// The hack used above is close enough to produce a visually consistent value, even though it is still a bit off.
//				let normalSize = NSString(string: " ").size(withAttributes: textView.typingAttributes).height
				columnRect = CGRect(x: 0, y: 0, width: gutterWidth - 8.0, height: normalSize)
			}

			columnRect = columnRect.offsetBy(dx: 0, dy: emptyText ? heightInset : 0.0)

			let drawRect = columnRect.offsetBy(dx: 0, dy: (columnRect.height - size.height) / 2 - topScrollOffset)

			numberString.draw(in: drawRect, withAttributes: gutterAttributes)
		}
	}

	override var requiredThickness: CGFloat
	{
		let defaultThickness = CGFloat(20.0)
		var lineCount = 1

		if let textLineCount = textView?.textMetrics?.lines, textLineCount > 0
		{
			lineCount = textLineCount
		}

		let digits = Int(log10(Double(lineCount)) + 1)
		let sampleString = String(repeating: "8", count: digits) as NSString
		let requiredThickness = sampleString.size(withAttributes: numberTextAttributes).width

		return ceil(max(defaultThickness, 8.0 + requiredThickness + kRulerMargin * 2.0))
	}

	// MARK: - Private Methods

	private func setupStateObservers()
	{
		Preferences.instance.addObserver(self, forKeyPath: "lineNumbersFont", options: .new, context: nil)
		Preferences.instance.addObserver(self, forKeyPath: "editorFont", options: .new, context: nil)
	}

	private var textView: EditorView?
	{
		return clientView as? EditorView
	}

	private var usesRTL: Bool
	{
		return NSApplication.shared.userInterfaceLayoutDirection == .rightToLeft
	}

	private var numberParagraphStyle: NSParagraphStyle
	{
		let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle

		style.alignment = usesRTL ? .left : .right

		return style
	}

	private var numberTextAttributes: [NSAttributedString.Key : Any]
	{
		return [
			.font: font,
			.foregroundColor: textColor,
			.paragraphStyle: numberParagraphStyle
		]
	}

	private var selectedNumberTextAttributes: [NSAttributedString.Key : Any]
	{
		return [
			.font: font,
			.foregroundColor: backgroundColor.isDarkColor ? NSColor.white : NSColor.black,
			.paragraphStyle: numberParagraphStyle
		]
	}
}
