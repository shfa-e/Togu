//
//  AirtableConfig.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import Foundation


struct AirtableConfig {
	let apiKey: String
	let baseId: String
	let questionsTable: String

	init?() {
		let info = Bundle.main.infoDictionary ?? [:]
		guard let apiKey = info["AIRTABLE_KEY"] as? String, !apiKey.isEmpty,
				let baseId = info["AIRTABLE_BASE_ID"] as? String, !baseId.isEmpty else {
			return nil
		}
		self.apiKey = apiKey
		self.baseId = baseId
		self.questionsTable = (info["AIRTABLE_TABLE_QUESTIONS"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (info["AIRTABLE_TABLE_QUESTIONS"] as! String) : "Questions"
	}
}
