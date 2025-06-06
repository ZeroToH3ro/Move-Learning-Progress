/*
/// Module: object_lesson_2
module object_lesson_2::object_lesson_2;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module object_lesson_2::transcript {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    public struct WrappableTranscript has key, store{
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

    const ENotIntendedAddress: u64 = 1;

    public entry fun create_wrappable_transcript_object(history: u8, math: u8, literature: u8, ctx: &mut TxContext) {
        let wrappableTranscript = WrappableTranscript {
            id: object::new(ctx),
            history,
            math,
            literature,
        };
        transfer::transfer(wrappableTranscript, tx_context::sender(ctx))
    }

    // You are allowed to retrieve the score but cannot modify it
    public fun view_score(transcriptObject: &WrappableTranscript): u8{
        transcriptObject.literature
    }

    // You are allowed to view and edit the score but not allowed to delete it
    public entry fun update_score(transcriptObject: &mut WrappableTranscript, score: u8){
        transcriptObject.literature = score
    }

    // You are allowed to do anything with the score, including view, edit, delete the entire transcript itself.
    public entry fun delete_transcript(transcriptObject: WrappableTranscript){
        let WrappableTranscript {id, history: _, math: _, literature: _ } = transcriptObject;
        object::delete(id);
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