-- Seed known DC-area music venues
INSERT INTO venues (name, slug, address, neighborhood, capacity, venue_type, website_url) VALUES
    ('Black Cat', 'black-cat', '1811 14th St NW, Washington, DC 20009', 'U Street', 550, 'club', 'https://www.blackcatdc.com'),
    ('DC9 Nightclub', 'dc9', '1940 9th St NW, Washington, DC 20001', 'U Street', 200, 'club', 'https://www.dc9.club'),
    ('Songbyrd Music House', 'songbyrd', '540 Penn St NE, Washington, DC 20002', 'Union Market', 300, 'club', 'https://www.songbyrddc.com'),
    ('Union Stage', 'union-stage', '740 Water St SW, Washington, DC 20024', 'The Wharf', 700, 'club', 'https://www.unionstage.com'),
    ('Pie Shop', 'pie-shop', '1339 H St NE, Washington, DC 20002', 'H Street', 150, 'bar', 'https://www.pieshopdc.com'),
    ('9:30 Club', '9-30-club', '815 V St NW, Washington, DC 20001', 'U Street', 1200, 'club', 'https://www.930.com'),
    ('The Anthem', 'the-anthem', '901 Wharf St SW, Washington, DC 20024', 'The Wharf', 6000, 'venue', 'https://www.theanthemdc.com'),
    ('Comet Ping Pong', 'comet-ping-pong', '5037 Connecticut Ave NW, Washington, DC 20008', 'Chevy Chase', 100, 'bar', 'https://www.cometpingpong.com'),
    ('Rhizome DC', 'rhizome-dc', '6950 Maple St NW, Washington, DC 20012', 'Takoma', 100, 'diy', 'https://www.rhizomedc.org'),
    ('The Pocket (7 Drum City)', '7-drum-city', '2611 Bladensburg Rd NE, Washington, DC 20018', 'Ivy City', 75, 'diy', 'https://thepocket.7drumcity.com'),
    ('The Howard Theatre', 'howard-theatre', '620 T St NW, Washington, DC 20001', 'Shaw', 1150, 'venue', 'https://www.thehowardtheatre.com'),
    ('Pearl Street Warehouse', 'pearl-street-warehouse', '33 Pearl St SW, Washington, DC 20024', 'The Wharf', 300, 'club', 'https://www.pearlstreetwarehouse.com'),
    ('Atlantis', 'atlantis', '911 U St NW, Washington, DC 20001', 'U Street', 200, 'club', 'https://www.atlantisdc.com'),
    ('Slash Run', 'slash-run', '1112 Neal Pl NE, Washington, DC 20002', 'Union Market', 100, 'bar', 'https://www.slashrundc.com')
ON CONFLICT (slug) DO NOTHING;
