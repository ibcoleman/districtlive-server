-- Fix venue name to match Ticketmaster's listing ("The Atlantis")
UPDATE venues SET name = 'The Atlantis', slug = 'the-atlantis' WHERE slug = 'atlantis';

delete from venues where slug = 'the-atlantis';