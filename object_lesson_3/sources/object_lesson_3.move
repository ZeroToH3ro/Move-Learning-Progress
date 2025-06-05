/*
/// Module: object_lesson_3
module object_lesson_3::object_lesson_3;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module object_lesson_3::transcript {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::u8;

    public struct WrappableTranscript has key, store {
        id: UID,
        history: u8,
        math: u8,
        literature: u8
    }

    public struct Folder has key {
        id: UID,
        transcript: WrappableTranscript,
        intended_address: address
    }

    public struct TeacherCap has key {
        id: UID,
    }

    // Error code for when a non-indended address tries to unpack the transcript wrapper 
    const ENotIntendedAddress: u64 = 1;

    fun init(ctx: &mut TxContext) {
        transfer::transfer(TeacherCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }

    public entry fun add_additional_teacher(_: &TeacherCap, new_teacher_address: address, ctx: &mut TxContext) {
        transfer::transfer(TeacherCap {
            id: object::new(ctx)
        },
         new_teacher_address)
    }

    public entry fun create_wrappable_transcript_object(_: &TeacherCap, history: u8, math: u8, literature: u8, ctx: &mut TxContext) {
        let transcript = WrappableTranscript {
            id: object::new(ctx),
            history,
            math,
            literature
        };
        transfer::transfer(transcript, tx_context::sender(ctx));
    }

    public fun view_score_history(transcriptObject: &WrappableTranscript): u8 {
        transcriptObject.history
    }


    public fun view_score_math(transcriptObject: &WrappableTranscript): u8 {
        transcriptObject.math
    }
    
    public fun view_score_literature(transcriptObject: &WrappableTranscript): u8 {
        transcriptObject.literature
    }

    public entry fun update_score_history(_: &TeacherCap, transcriptObject: &mut WrappableTranscript, score: u8) {
        transcriptObject.history = score
    }

    public entry fun request_transcript(transcript: WrappableTranscript, intended_address: address, ctx: &mut TxContext){
        let folderObject = Folder {
            id: object::new(ctx),
            transcript,
            intended_address
        };
        //We transfer the wrapped transcript object directly to the intended address
        transfer::transfer(folderObject, intended_address)
    }

    public entry fun unpack_wrapped_transcript(folder: Folder, ctx: &mut TxContext){
        // Check that the person unpacking the transcript is the intended viewer
        assert!(folder.intended_address == tx_context::sender(ctx), ENotIntendedAddress);
        let Folder {
            id,
            transcript,
            intended_address:_,
        } = folder;
        transfer::transfer(transcript, tx_context::sender(ctx));
        object::delete(id)
    }
}