//
//  BlockEditorViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import SwiftData
import Observation

/// ViewModel for the block-based editor
@MainActor
@Observable
final class BlockEditorViewModel {
    // MARK: - Properties

    /// Knowledge entry being edited
    var entry: KnowledgeEntry

    /// All blocks for this entry (sorted)
    var blocks: [ContentBlock] = []

    /// Currently focused block
    var focusedBlockID: UUID?

    /// Currently selected blocks (for multi-select)
    var selectedBlockIDs: Set<UUID> = []

    /// Slash menu state
    var showingSlashMenu = false
    var slashMenuBlockID: UUID?
    var slashMenuSearchText = ""

    /// Undo/Redo stacks
    private var undoStack: [EditorState] = []
    private var redoStack: [EditorState] = []

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(entry: KnowledgeEntry, modelContext: ModelContext) {
        self.entry = entry
        self.modelContext = modelContext
        loadBlocks()
    }

    // MARK: - Block Management

    /// Load blocks from entry
    func loadBlocks() {
        blocks = entry.getSortedBlocks()

        // Create initial block if empty
        if blocks.isEmpty {
            let initialBlock = ContentBlock(
                type: .text,
                content: "",
                order: 0,
                entryID: UUID(uuidString: entry.id) ?? UUID()
            )
            addBlock(initialBlock)
        }
    }

    /// Add new block
    func addBlock(_ block: ContentBlock, at index: Int? = nil) {
        saveState() // For undo

        modelContext.insert(block)
        entry.addBlock(block)

        if let index = index {
            blocks.insert(block, at: index)
            reorderBlocks()
        } else {
            blocks.append(block)
        }

        entry.touch()
    }

    /// Add block after another block
    func addBlockAfter(_ afterBlock: ContentBlock, type: BlockType = .text) {
        guard let index = blocks.firstIndex(where: { $0.id == afterBlock.id }) else { return }

        let newBlock = ContentBlock(
            type: type,
            content: "",
            order: afterBlock.order + 1,
            entryID: UUID(uuidString: entry.id) ?? UUID()
        )

        addBlock(newBlock, at: index + 1)
        focusedBlockID = newBlock.id
    }

    /// Delete block
    func deleteBlock(_ block: ContentBlock) {
        saveState() // For undo

        blocks.removeAll { $0.id == block.id }
        entry.removeBlock(block)
        modelContext.delete(block)
        entry.touch()

        // Focus previous block if exists
        if let index = blocks.firstIndex(where: { $0.id == block.id }),
           index > 0 {
            focusedBlockID = blocks[index - 1].id
        }
    }

    /// Delete selected blocks
    func deleteSelectedBlocks() {
        guard !selectedBlockIDs.isEmpty else { return }

        saveState() // For undo

        for blockID in selectedBlockIDs {
            if let block = blocks.first(where: { $0.id == blockID }) {
                deleteBlock(block)
            }
        }

        selectedBlockIDs.removeAll()
    }

    /// Move block
    func moveBlock(from source: IndexSet, to destination: Int) {
        saveState() // For undo

        blocks.move(fromOffsets: source, toOffset: destination)
        reorderBlocks()
        entry.touch()
    }

    /// Move block by ID before another block
    func moveBlock(withID draggedID: UUID, before targetID: UUID) {
        guard let draggedIndex = blocks.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = blocks.firstIndex(where: { $0.id == targetID }),
              draggedIndex != targetIndex else { return }

        saveState() // For undo

        let block = blocks.remove(at: draggedIndex)
        let newIndex = draggedIndex < targetIndex ? targetIndex - 1 : targetIndex
        blocks.insert(block, at: newIndex)

        reorderBlocks()
        entry.touch()
    }

    /// Reorder blocks after move
    private func reorderBlocks() {
        for (index, block) in blocks.enumerated() {
            block.order = index
        }
        entry.reorderBlocks(blocks)
    }

    /// Convert block type
    func convertBlock(_ block: ContentBlock, to type: BlockType) {
        saveState() // For undo

        block.convertTo(type: type)
        entry.touch()
    }

    /// Update block content
    func updateBlockContent(_ block: ContentBlock, content: String) {
        block.updateContent(content)
        entry.touch()
    }

    // MARK: - Indentation

    /// Indent block
    func indentBlock(_ block: ContentBlock) {
        saveState() // For undo

        block.indent()
        entry.touch()
    }

    /// Outdent block
    func outdentBlock(_ block: ContentBlock) {
        saveState() // For undo

        block.outdent()
        entry.touch()
    }

    // MARK: - Focus Management

    /// Focus next block
    func focusNextBlock() {
        guard let currentID = focusedBlockID,
              let currentIndex = blocks.firstIndex(where: { $0.id == currentID }),
              currentIndex < blocks.count - 1 else { return }

        focusedBlockID = blocks[currentIndex + 1].id
    }

    /// Focus previous block
    func focusPreviousBlock() {
        guard let currentID = focusedBlockID,
              let currentIndex = blocks.firstIndex(where: { $0.id == currentID }),
              currentIndex > 0 else { return }

        focusedBlockID = blocks[currentIndex - 1].id
    }

    // MARK: - Slash Menu

    /// Show slash menu for block
    func showSlashMenu(for blockID: UUID) {
        slashMenuBlockID = blockID
        showingSlashMenu = true
        slashMenuSearchText = ""
    }

    /// Hide slash menu
    func hideSlashMenu() {
        showingSlashMenu = false
        slashMenuBlockID = nil
        slashMenuSearchText = ""
    }

    /// Select block type from slash menu
    func selectBlockType(_ type: BlockType) {
        guard let blockID = slashMenuBlockID,
              let block = blocks.first(where: { $0.id == blockID }) else { return }

        convertBlock(block, to: type)
        hideSlashMenu()
    }

    // MARK: - Undo/Redo

    /// Save current state for undo
    private func saveState() {
        let state = EditorState(blocks: blocks.map { $0 })
        undoStack.append(state)

        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }

        // Clear redo stack on new action
        redoStack.removeAll()
    }

    /// Undo last action
    func undo() {
        guard let lastState = undoStack.popLast() else { return }

        // Save current state to redo
        let currentState = EditorState(blocks: blocks.map { $0 })
        redoStack.append(currentState)

        // Restore last state
        restoreState(lastState)
    }

    /// Redo last undone action
    func redo() {
        guard let nextState = redoStack.popLast() else { return }

        // Save current state to undo
        let currentState = EditorState(blocks: blocks.map { $0 })
        undoStack.append(currentState)

        // Restore next state
        restoreState(nextState)
    }

    private func restoreState(_ state: EditorState) {
        // This is simplified - in production, you'd need more sophisticated state restoration
        blocks = state.blocks
        entry.reorderBlocks(blocks)
    }

    // MARK: - Save

    /// Save changes to model context
    func save() throws {
        try modelContext.save()
    }
}

// MARK: - Editor State

private struct EditorState {
    let blocks: [ContentBlock]
}
