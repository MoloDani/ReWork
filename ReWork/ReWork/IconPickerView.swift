//
//  IconPickerView.swift
//  ReWork
//
//  Created by Daniel Molodet on 27/08/2026.
//

import SwiftUI
import ReWork_package

struct IconPickerView: View {
    @Binding var selection: String
    let tint: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(IconCatalog.groups) { group in
                    Text(group.id.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 2)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 54), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(group.symbols, id: \.self) { symbol in
                            cell(symbol)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Choose Icon")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func cell(_ symbol: String) -> some View {
        let selected = selection == symbol

        return Button {
            selection = symbol
            dismiss()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(selected ? Color(hex: tint) : .primary)
                .frame(width: 54, height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(selected ? Color(hex: tint).opacity(0.2) : Color.primary.opacity(0.05))
                )
                // Without this only the glyph is tappable, not the cell.
                .contentShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}
