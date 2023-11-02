//
//  PrintAccessoryViewController.swift
//  Notedown
//
//  Created by Bruno Philipe on 12/3/17.
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

class PrintAccessoryViewController: NSViewController
{
	@IBOutlet fileprivate var checkboxRewrapContents: NSButton!
	@IBOutlet fileprivate var checkboxShowFilename: NSButton!
	@IBOutlet fileprivate var checkboxShowDate: NSButton!
	@IBOutlet fileprivate var checkboxShowPageNumber: NSButton!
	@IBOutlet fileprivate var checkboxShowLineNumbers: NSButton!
	@IBOutlet fileprivate var radioButtonNoTheme: NSButton!
	@IBOutlet fileprivate var radioButtonUseTheme: NSButton!
	@IBOutlet fileprivate var popUpButtonThemes: NSPopUpButton!

	@objc dynamic var rewrapContents: NSNumber
	{
		get { return NSNumber(booleanLiteral: Preferences.instance.printWrapContents) }
		set { Preferences.instance.printWrapContents = newValue.boolValue }
	}

	@objc dynamic var showFileName: NSNumber
	{
		get { return NSNumber(booleanLiteral: Preferences.instance.printShowFileName) }
		set { Preferences.instance.printShowFileName = newValue.boolValue }
	}

	@objc dynamic var showDate: NSNumber
	{
		get { return NSNumber(booleanLiteral: Preferences.instance.printShowDate) }
		set { Preferences.instance.printShowDate = newValue.boolValue }
	}

	@objc dynamic var showPageNumber: NSNumber
	{
		get { return NSNumber(booleanLiteral: Preferences.instance.printShowPageNumber) }
		set { Preferences.instance.printShowPageNumber = newValue.boolValue }
	}

	@objc dynamic var showLineNumbers: NSNumber
	{
		get { return NSNumber(booleanLiteral: Preferences.instance.printHideLineNumbers) }
		set { Preferences.instance.printHideLineNumbers = newValue.boolValue }
	}

	@objc dynamic var usesTheme: NSNumber
	{
		get { return NSNumber(booleanLiteral: Preferences.instance.printUseCustomTheme) }
		set { Preferences.instance.printUseCustomTheme = newValue.boolValue }
	}

	@objc dynamic var themeName: String
	{
		get { return Preferences.instance.printThemeName }
		set { Preferences.instance.printThemeName = newValue }
	}

	fileprivate let observedProperties = [
		"rewrapContents",
		"showFileName",
		"showDate",
		"showPageNumber",
		"showLineNumbers",
		"usesTheme",
		"themeName"
	]

	override func awakeFromNib()
	{
		title = "Notedown"
	}

    override func viewDidLoad()
	{
        super.viewDidLoad()
        // Do view setup here.

		updateThemesMenu()

		let usesCustomTheme = Preferences.instance.printUseCustomTheme
		radioButtonNoTheme.state = NSControl.StateValue(rawValue: usesCustomTheme ? 0 : 1)
		radioButtonUseTheme.state = NSControl.StateValue(rawValue: usesCustomTheme ? 1 : 0)

		popUpButtonThemes.isEnabled = usesCustomTheme
    }

	override var representedObject: Any?
	{
		didSet
		{
			for observedProperty in observedProperties
			{
				addObserver(self, forKeyPath: observedProperty, context: nil)
			}
		}
	}

	deinit
	{
		if representedObject != nil
		{
			for observedProperty in observedProperties
			{
				removeObserver(self, forKeyPath: observedProperty)
			}
		}
	}

	override func observeValue(forKeyPath keyPath: String?,
							   of object: Any?,
							   change: [NSKeyValueChangeKey : Any]?,
							   context: UnsafeMutableRawPointer?)
	{

	}

	private func updateThemesMenu()
	{
		let menu = NSMenu()

		let themes = ConcreteEditorTheme.installedThemes()
		var selectedItem: NSMenuItem? = nil

		for theme in themes.native
		{
			menu.addItem(NSMenuItem.itemForEditorTheme(theme,
													   &selectedItem,
													   target: self,
													   #selector(PrintAccessoryViewController.didChangeEditorTheme(_:)),
													   selectedThemeName: themeName))
		}

		if themes.user.count > 0
		{
			menu.addItem(NSMenuItem.separator())

			for theme in themes.user
			{
				menu.addItem(NSMenuItem.itemForEditorTheme(theme,
														   &selectedItem,
														   target: self,
														   #selector(PrintAccessoryViewController.didChangeEditorTheme(_:)),
														   selectedThemeName: themeName))
			}
		}

		if selectedItem == nil
		{
			selectedItem = menu.items.first
		}

		popUpButtonThemes.menu = menu
		popUpButtonThemes.select(selectedItem)
	}
}

extension PrintAccessoryViewController // IBActions
{
	@IBAction func didClickRadioButton(_ sender: NSButton)
	{
		switch sender.tag
		{
		case 1:
			self.usesTheme = false
			popUpButtonThemes.isEnabled = false

		case 2:
			self.usesTheme = true
			popUpButtonThemes.isEnabled = true

		default:
			break
		}
	}

	@IBAction func didChangeEditorTheme(_ sender: NSMenuItem?)
	{
		if let theme = sender?.representedObject as? EditorTheme, let themeName = theme.preferenceName
		{
			self.themeName = themeName
		}
		else
		{
			self.themeName = PrintingEditorTheme().preferenceName!
		}
	}
}

extension PrintAccessoryViewController // Maker
{
	static func make() -> PrintAccessoryViewController
	{
		return PrintAccessoryViewController(nibName: "PrintAccessoryViewController", bundle: Bundle.main)
	}
}

extension PrintAccessoryViewController: NSPrintPanelAccessorizing
{
	func localizedSummaryItems() -> [[NSPrintPanel.AccessorySummaryKey : String]]
	{
		return [[:]]
	}

	func keyPathsForValuesAffectingPreview() -> Set<String>
	{
		return Set(observedProperties)
	}
}
