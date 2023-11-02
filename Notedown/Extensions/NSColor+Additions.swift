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

import Cocoa

extension NSColor
{
	convenience init(rgb: UInt)
	{
		self.init(rgba: (rgb << 8) | 0x000000FF)
	}

	convenience init(rgba: UInt)
	{
		let red		= CGFloat((rgba >> 24) & 0x000000FF) / CGFloat(255.0)
		let green	= CGFloat((rgba >> 16) & 0x000000FF) / CGFloat(255.0)
		let blue	= CGFloat((rgba >>  8) & 0x000000FF) / CGFloat(255.0)
		let alpha	= CGFloat((rgba >>  0) & 0x000000FF) / CGFloat(255.0)

		self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
	}

	static func fromData(_ data: Data) -> NSColor?
	{
		return NSUnarchiver.unarchiveObject(with: data) as? NSColor
	}

	var rgb: UInt
	{
		if colorSpace == NSColorSpace.sRGB
		{
			var rgbInt = UInt(0)
			
			rgbInt |= UInt(redComponent   * 255) << 16
			rgbInt |= UInt(greenComponent * 255) << 8
			rgbInt |= UInt(blueComponent  * 255) << 0
			
			return rgbInt
		}
		
		return self.usingColorSpace(NSColorSpace.sRGB)?.rgb ?? 0
	}

	var rgba: UInt
	{
		return (rgb << 8) | (UInt(alphaComponent * 255) & 0x000000FF)
	}

	var data: Data
	{
		return NSArchiver.archivedData(withRootObject: self)
	}
	
	var luminance: CGFloat
	{
		if let rgb = self.usingColorSpace(NSColorSpace.deviceRGB)
		{
			return 0.2126*rgb.redComponent + 0.7152*rgb.greenComponent + 0.0722*rgb.blueComponent
		}
		
		return 0
	}

	var isDarkColor: Bool
	{
		return luminance < 0.5
	}
}
