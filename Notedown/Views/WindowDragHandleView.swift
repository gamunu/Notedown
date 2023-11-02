//
//  EditorTheme.swift
//  Notedown
//
//  Created by Bruno Philipe on 11/07/2017.
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

// Inheriting from a concrete NSControl was the only hack I found to get mouse events that wouldn't be overriden by NSTextView.
class WindowDragHandleView: NSTextField
{
	private var trackingArea: NSTrackingArea? = nil

	override func viewDidMoveToWindow()
	{
		super.viewDidMoveToWindow()

		translatesAutoresizingMaskIntoConstraints = false
		isEnabled = false
		isBordered = false
		drawsBackground = true
		alphaValue = 0.0
	}

	override var isOpaque: Bool
	{
		return false
	}

	override func updateTrackingAreas()
	{
		if let trackingArea = self.trackingArea
		{
			removeTrackingArea(trackingArea)
		}

		let trackingArea = NSTrackingArea(rect: bounds,
		                                  options: [.activeAlways, .enabledDuringMouseDrag, .mouseEnteredAndExited],
		                                  owner: self,
		                                  userInfo: nil)

		addTrackingArea(trackingArea)

		self.trackingArea = trackingArea

		super.updateTrackingAreas()
	}

	override func resetCursorRects()
	{
		addCursorRect(bounds, cursor: .crosshair)
	}

	override func mouseEntered(with event: NSEvent)
	{
		super.mouseEntered(with: event)

		if !isHidden
		{
			animator().alphaValue = 1.0
		}
	}

	override func mouseExited(with event: NSEvent)
	{
		super.mouseExited(with: event)

		if !isHidden
		{
			animator().alphaValue = 0.0
		}
	}
}
