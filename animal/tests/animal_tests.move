#[test_only]
module animal::animal_tests {
    use animal::animal;
    use sui::test_scenario;
    use std::string;

    #[test]
    fun test_create_anime_object() {
        let admin = @0xABCD;
        let mut scenario = test_scenario::begin(admin);
        
        // Create an animal object
        animal::create_anime_object(
            b"Cat",
            4,
            b"Fish",
            test_scenario::ctx(&mut scenario)
        );
        
        // Check that the object was created and transferred
        test_scenario::next_tx(&mut scenario, admin);
        
        let anime_object = test_scenario::take_from_sender<animal::AnimeObject>(&scenario);
        
        // Verify the properties
        assert!(animal::get_name(&anime_object) == string::utf8(b"Cat"));
        assert!(animal::get_no_of_legs(&anime_object) == 4);
        assert!(animal::get_favorite_food(&anime_object) == string::utf8(b"Fish"));
        
        test_scenario::return_to_sender(&scenario, anime_object);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_different_animals() {
        let admin = @0xABCD;
        let mut scenario = test_scenario::begin(admin);
        
        // Create a dog
        animal::create_anime_object(
            b"Dog",
            4,
            b"Bones",
            test_scenario::ctx(&mut scenario)
        );
        
        // Create a spider
        animal::create_anime_object(
            b"Spider",
            8,
            b"Flies",
            test_scenario::ctx(&mut scenario)
        );
        
        test_scenario::next_tx(&mut scenario, admin);
        
        // Should have 2 objects now
        let ids = test_scenario::ids_for_sender<animal::AnimeObject>(&scenario);
        assert!(ids.length() == 2);
        
        test_scenario::end(scenario);
    }
}
