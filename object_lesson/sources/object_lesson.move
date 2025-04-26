/*
/// Module: object_lesson
module object_lesson::object_lesson;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module object_lesson::object_lesson {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    public struct Transcript {
        history: u8,
        math: u8,
        literature: u8
    }

    public struct TranscriptObject has key, store {
        id: UID,
        history: u8,
        math: u8,
        literature: u8
    }

    public entry fun create_transcript_object(history: u8, math: u8, literature: u8, ctx: &mut TxContext) {
        let transcriptObject = TranscriptObject {
            id: object::new(ctx),
            history,
            math,
            literature,
        };
        transfer::transfer(transcriptObject, tx_context::sender(ctx))
    }

    // You ar allowed to retrieve the score but cannot modify it
    public fun view_score(transcriptObject: &TranscriptObject): (u8, u8, u8) {
        (transcriptObject.history, transcriptObject.math, transcriptObject.literature)
    }

    // You are allowed to retrieve the score but can not modify it
    public entry fun update_score_history(transcriptObject: &mut TranscriptObject, score: u8) {
        transcriptObject.history = score;
    }

    public entry fun update_score_literature(transcriptObject: &mut TranscriptObject, score: u8) {
        transcriptObject.literature = score;
    }

    public entry fun update_score_math(transcriptObject: &mut TranscriptObject, score: u8) {
        transcriptObject.math = score;
    }

    public entry fun delete_transcript(transcriptObject: TranscriptObject) {
        let TranscriptObject { id, history:_, math:_, literature:_ } = transcriptObject;
        object::delete(id);
    }
}