//
//  EditorTheme.swift
//  Notedown
//
//  Created by Bruno Philipe on 23/02/2017.
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

protocol EditorTheme: class
{
	var name: String { get }
	
	var editorForeground: NSColor { get }
	var editorBackground: NSColor { get }
	
	var lineNumbersForeground: NSColor { get }
	var lineNumbersBackground: NSColor { get }

	var preferenceName: String? { get }
	
	var invisiblesForeground: NSColor { get }
}

private let kThemeNameKey					= "name"
private let kThemeEditorBackgroundKey		= "editor_background"
private let kThemeLineNumbersBackgroundKey	= "lines_background"
private let kThemeEditorForegroundKey		= "editor_foreground"
private let kThemeLineNumbersForegroundKey	= "lines_foreground"

private let kThemeNativeNamePrefix = "native:"
private let kThemeUserNamePrefix = "user:"

extension EditorTheme
{
	fileprivate static var userThemeKeys: [String]
	{
		return [
			kThemeEditorBackgroundKey,
			kThemeLineNumbersBackgroundKey,
			kThemeEditorForegroundKey,
			kThemeLineNumbersForegroundKey
		]
	}

	fileprivate var serialized: [String: AnyObject]
	{
		return [
			kThemeNameKey:					name as NSString,
			kThemeEditorBackgroundKey:		editorBackground,
			kThemeLineNumbersBackgroundKey:	lineNumbersBackground,
			kThemeEditorForegroundKey:		editorForeground,
			kThemeLineNumbersForegroundKey:	lineNumbersForeground
		]
	}
	
	func make(fromSerialized dict: [String: AnyObject]) -> EditorTheme
	{
		return UserEditorTheme(fromSerialized: dict)
	}

	static func installedThemes() -> (native: [EditorTheme], user: [EditorTheme])
	{
		let nativeThemes: [EditorTheme] = [
			LightEditorTheme(),
			DarkEditorTheme()
		]

		var userThemes: [EditorTheme] = []

		if let themesDirectoryURL = URLForUserThemesDirectory()
		{
			if let fileURLs = try? FileManager.default.contentsOfDirectory(at: themesDirectoryURL,
			                                                               includingPropertiesForKeys: nil,
			                                                               options: [.skipsHiddenFiles])
			{
				for fileURL in fileURLs
				{
					if fileURL.pathExtension == "plist", let theme = UserEditorTheme(fromFile: fileURL)
					{
						userThemes.append(theme)
					}
				}
			}
		}

		return (nativeThemes, userThemes)
	}

	static func URLForUserThemesDirectory() -> URL?
	{
		if let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
		{
			let themeDirectory = appSupportDirectory.appendingPathComponent("Notedown/Themes/")

			do
			{
				try FileManager.default.createDirectory(at: themeDirectory, withIntermediateDirectories: true, attributes: nil)
			}
			catch let error
			{
				NSLog("Could not create Themes directory: \(themeDirectory). Please check permissions. Error: \(error)")
			}

			return themeDirectory
		}

		return nil
	}

	public static func getWithPreferenceName(_ name: String) -> EditorTheme?
	{
		if name.hasPrefix(kThemeNativeNamePrefix)
		{
			let themeName = name[name.index(name.startIndex, offsetBy: kThemeNativeNamePrefix.count) ..< name.endIndex]

			switch themeName
			{
			case "Light":
				return LightEditorTheme()

			case "Dark":
				return DarkEditorTheme()

			default:
				return nil
			}
		}
		else if name.hasPrefix(kThemeUserNamePrefix)
		{
			let themeFilePath = String(name[name.index(name.startIndex, offsetBy: kThemeUserNamePrefix.count) ..< name.endIndex])

			if FileManager.default.fileExists(atPath: themeFilePath)
			{
				return UserEditorTheme(fromFile: URL(fileURLWithPath: themeFilePath))
			}
			else
			{
				return nil
			}
		}
		else
		{
			return nil
		}
	}
}

fileprivate extension NSColor
{
	var invisibles: NSColor
	{
		return withAlphaComponent(0.2)
	}
}

class ConcreteEditorTheme: NSObject, EditorTheme
{
	init(name: String, editorForeground: NSColor, editorBackground: NSColor, lineNumbersForeground: NSColor, lineNumbersBackground: NSColor)
	{
		self.name = name
		self.editorForeground = editorForeground
		self.editorBackground = editorBackground
		self.lineNumbersForeground = lineNumbersForeground
		self.lineNumbersBackground = lineNumbersBackground
	}
	
	fileprivate(set) var name: String
	
	/// Color to be used for invisible characters rendering. It is based on the foreground 
	lazy var invisiblesForeground: NSColor = editorForeground.invisibles

	@objc dynamic var editorForeground: NSColor
	@objc dynamic var editorBackground: NSColor
	@objc dynamic var lineNumbersForeground: NSColor
	@objc dynamic var lineNumbersBackground: NSColor

	@objc dynamic var willDeallocate: Bool = false

	var preferenceName: String?
	{
		return "\(kThemeNativeNamePrefix)\(name)"
	}

	func makeCustom() -> EditorTheme?
	{
		return UserEditorTheme(customizingTheme: self)
	}
}

class UserEditorTheme : ConcreteEditorTheme
{
	fileprivate init(fromSerialized dict: [String: AnyObject])
	{
		super.init(name: (dict[kThemeNameKey] as? String) ?? "(Unamed)",
				   editorForeground: (dict[kThemeEditorForegroundKey] as? NSColor) ?? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
				   editorBackground: (dict[kThemeEditorBackgroundKey] as? NSColor) ?? #colorLiteral(red: 0.9921568627, green: 0.9921568627, blue: 0.9921568627, alpha: 1),
				   lineNumbersForeground: (dict[kThemeLineNumbersForegroundKey] as? NSColor) ?? #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1),
				   lineNumbersBackground: (dict[kThemeLineNumbersBackgroundKey] as? NSColor) ?? #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1))
	}
	
	fileprivate var fileWriterOldURL: URL? = nil
	fileprivate var fileWriterTimer: Timer? = nil

	fileprivate var fileURL: URL?
	{
		if let themesDirectory = UserEditorTheme.URLForUserThemesDirectory()
		{
			return themesDirectory.appendingPathComponent(name).appendingPathExtension("plist")
		}
		else
		{
			return nil
		}
	}

	convenience init(customizingTheme originalTheme: EditorTheme)
	{
		self.init(fromSerialized: originalTheme.serialized)
		
		name = originalTheme.name.appending(" (Custom)")
	}

	convenience init?(fromFile fileURL: URL)
	{
		if fileURL.isFileURL,
			let data = try? Data(contentsOf: fileURL),
			var themeDictionary = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String : AnyObject]
		{
			for itemKey in UserEditorTheme.userThemeKeys
			{
				if themeDictionary[itemKey] == nil
				{
					return nil
				}

				if let data = themeDictionary[itemKey] as? Data
				{
					themeDictionary[itemKey] = NSColor.fromData(data) ?? NSColor.white
				}
				else if let intValue = themeDictionary[itemKey] as? UInt
				{
					themeDictionary[itemKey] = NSColor(rgb: intValue)
				}
			}
			
			self.init(fromSerialized: themeDictionary)
			
			name = fileURL.deletingPathExtension().lastPathComponent
		}
		else
		{
			return nil
		}
	}

	var isCustomization: Bool
	{
		return name.hasSuffix("(Custom)")
	}

	override var preferenceName: String?
	{
		if let fileURL = self.fileURL
		{
			return "\(kThemeUserNamePrefix)\(fileURL.path)"
		}

		return nil
	}

	override func didChangeValue(forKey key: String)
	{
		super.didChangeValue(forKey: key)

		if !["name", "willDeallocate"].contains(key)
		{
			writeToFile(immediatelly: false)
		}
	}

	func renameTheme(newName: String) -> Bool
	{
		if let oldUrl = fileURL
		{
			fileWriterOldURL = oldUrl

			name = newName

			return moveThemeFile()
		}

		return false
	}

	func deleteTheme() -> Bool
	{
		return deleteThemeFile()
	}
}

extension UserEditorTheme
{
	func writeToFile(immediatelly: Bool)
	{
		if immediatelly
		{
			writeToFileNow()
			fileWriterTimer?.invalidate()
			fileWriterTimer = nil
		}
		else
		{
			if let timer = self.fileWriterTimer
			{
				timer.fireDate = Date().addingTimeInterval(3)
			}
			else
			{
				fileWriterTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false)
				{
					(timer) in

					self.writeToFileNow()
					self.fileWriterTimer = nil
				}
			}
		}
	}

	func exportThemeTo(url targetUrl: URL)
	{
		writeToFileNow(url: targetUrl)
	}

	private func writeToFileNow(url targetUrl: URL? = nil)
	{
		if let url = targetUrl ?? self.fileURL
		{
			let serialized = self.serialized
			let dict = (serialized as NSDictionary).mutableCopy() as! NSMutableDictionary

			for settingKey in serialized.keys
			{
				if let color = dict[settingKey] as? NSColor
				{
					dict.setValue(color.data, forKey: settingKey)
				}
			}

			do
			{
				try PropertyListSerialization.data(fromPropertyList: dict,
				                                   format: .binary,
				                                   options: 0).write(to: url,
				                                                     options: .atomicWrite)
				print("Now 1")
			}
			catch
			{
				print("Now 2")
				dict.write(to: url, atomically: true)
			}
		}
	}

	fileprivate func moveThemeFile() -> Bool
	{
		if let oldURL = fileWriterOldURL, let newURL = fileURL
		{
			do
			{
				try FileManager.default.moveItem(at: oldURL, to: newURL)

				fileWriterOldURL = nil

				// We have to write now so we update the theme name.
				writeToFileNow()

				return true
			}
			catch let error
			{
				NSLog("Error! Could not rename theme file! \(error)")

				return false
			}
		}

		return false
	}

	fileprivate func deleteThemeFile() -> Bool
	{
		if let url = fileURL
		{
			do
			{
				try FileManager.default.removeItem(at: url)

				return true
			}
			catch let error
			{
				NSLog("Error! Could not delete theme file! \(error)")
			}
		}

		return false
	}
}

class NativeEditorTheme: ConcreteEditorTheme
{
	
	
	override var preferenceName: String?
	{
		return "\(kThemeNativeNamePrefix)\(name)"
	}
}

class LightEditorTheme: NativeEditorTheme
{
	init()
	{
		super.init(name: "Light",
				   editorForeground: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
				   editorBackground: #colorLiteral(red: 0.9921568627, green: 0.9921568627, blue: 0.9921568627, alpha: 1),
				   lineNumbersForeground: #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1),
				   lineNumbersBackground: #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1))
	}
}

class DarkEditorTheme: NativeEditorTheme
{
	init()
	{
		super.init(name: "Dark",
				   editorForeground: #colorLiteral(red: 0.8588235294, green: 0.8588235294, blue: 0.8588235294, alpha: 1),
				   editorBackground: #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1),
				   lineNumbersForeground: #colorLiteral(red: 0.4549019608, green: 0.4549019608, blue: 0.4549019608, alpha: 1),
				   lineNumbersBackground: #colorLiteral(red: 0.1647058824, green: 0.1647058824, blue: 0.1647058824, alpha: 1))
	}
}

class PrintingEditorTheme: NativeEditorTheme
{
	init()
	{
		super.init(name: "Print",
				   editorForeground: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
				   editorBackground: #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1),
				   lineNumbersForeground: #colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 1),
				   lineNumbersBackground: #colorLiteral(red: 0.9688121676, green: 0.9688346982, blue: 0.9688225389, alpha: 1))
	}
}
