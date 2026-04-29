-- Add DC-proper venues found in Ticketmaster DMA 224 results
INSERT INTO venues (name, slug, address, neighborhood, capacity, venue_type, website_url) VALUES
    ('Echostage', 'echostage', '2135 Queens Chapel Rd NE, Washington, DC 20018', 'Queens Chapel', 3000, 'club', 'https://www.echostage.com'),
    ('Warner Theatre', 'warner-theatre', '513 13th St NW, Washington, DC 20004', 'Penn Quarter', 1847, 'venue', 'https://www.warnertheatredc.com'),
    ('Lincoln Theatre', 'lincoln-theatre', '1215 U St NW, Washington, DC 20009', 'U Street', 1227, 'venue', 'https://www.thelincolndc.com'),
    ('Capital One Arena', 'capital-one-arena', '601 F St NW, Washington, DC 20004', 'Chinatown', 20356, 'arena', 'https://www.capitalonearena.com'),
    ('DAR Constitution Hall', 'dar-constitution-hall', '1776 D St NW, Washington, DC 20006', 'Foggy Bottom', 3702, 'venue', 'https://www.dar.org/constitution-hall'),
    ('The National Theatre', 'the-national-theatre', '1321 Pennsylvania Ave NW, Washington, DC 20004', 'Penn Quarter', 1676, 'venue', 'https://www.thenationaldc.com')
ON CONFLICT (slug) DO NOTHING;
