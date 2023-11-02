//
// Created by Bruno Philipe on 8/3/17.
// Copyright (c) 2017 Bruno Philipe. All rights reserved.
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

import Foundation

extension String
{
	static let newLineChar = Character("\n")
	static let whitespaceCharset = NSCharacterSet.whitespacesAndNewlines

	var fullRange: Range<Index>
	{
		return startIndex..<endIndex
	}

	var metrics: StringMetrics
	{
		var wordsCount = 0
		var linesCount = 0
		var characterCount = 0
		var whitespaceCharsCount = 0
		let whitespaceCharacterSet = String.whitespaceCharset

		var lastCharWasWhitespace = true

		forEach
			{
				character in

				if String(character).rangeOfCharacter(from: whitespaceCharacterSet) == nil
				{
					characterCount += 1

					if lastCharWasWhitespace
					{
						wordsCount += 1
						lastCharWasWhitespace = false
					}
				}
				else
				{
					if character == String.newLineChar
					{
						linesCount += 1
					}

					whitespaceCharsCount += 1
					lastCharWasWhitespace = true
				}
			}

		if characterCount + whitespaceCharsCount > 0
		{
			linesCount += 1
		}

		return StringMetrics(characterCount, whitespaceCharsCount, wordsCount, linesCount)
	}
}

extension NSString
{
	var fullRange: NSRange
	{
		return NSMakeRange(0, length)
	}
}

struct StringMetrics: Equatable
{
	let chars: Int
	let whitespaceChars: Int
	let words: Int
	let lines: Int

	init()
	{
		self.init(0, 0, 0, 0)
	}

	init(_ characterCount: Int, _ whitespaceCharsCount: Int, _ wordsCount: Int, _ linesCount: Int)
	{
		chars = characterCount
		whitespaceChars = whitespaceCharsCount
		words = wordsCount
		lines = linesCount
	}

	var allCharacters: Int
	{
		return chars + whitespaceChars
	}
}

func +(lhs: StringMetrics, rhs: StringMetrics) -> StringMetrics
{
	return StringMetrics(lhs.chars + rhs.chars, lhs.whitespaceChars + rhs.whitespaceChars, lhs.words + rhs.words, lhs.lines + rhs.lines)
}

func -(lhs: StringMetrics, rhs: StringMetrics) -> StringMetrics
{
	return StringMetrics(lhs.chars - rhs.chars, lhs.whitespaceChars - rhs.whitespaceChars, lhs.words - rhs.words, lhs.lines - rhs.lines)
}

func ==(lhs: StringMetrics, rhs: StringMetrics) -> Bool
{
	return lhs.chars == rhs.chars && lhs.lines == rhs.lines && lhs.whitespaceChars == rhs.whitespaceChars && lhs.words == rhs.words
}

extension NSRange
{
	func advancing(by: Int) -> NSRange
	{
		return NSRange(location: max(location + by, 0), length: length)
	}

	/// Returns a range with the same location as the receiver and with length equal to the receiver's length if it is > 0, or 1 otherwise.
	var meaningfulRange: NSRange
	{
		return NSMakeRange(location, max(length, 1))
	}

	func expanding(by delta: Int) -> NSRange
	{
		return NSMakeRange(location, max(length + delta, 0))
	}

	func expanding(byEncapsulating delta: Int, maxLength: Int) -> NSRange
	{
		let newLocation = max(0, location - delta)
		let newLength = min(length + delta * 2, maxLength - newLocation)
		return NSMakeRange(newLocation, newLength)
	}

	var lowerBoundInsertionRange: NSRange
	{
		return NSMakeRange(lowerBound, 0)
	}

	var upperBoundInsertionRange: NSRange
	{
		return NSMakeRange(upperBound, 0)
	}
}
