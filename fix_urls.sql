UPDATE users SET avatarUrl = REPLACE(avatarUrl, 'https://sirvya-1c5de0abe34c.herokuapp.com', 'http://51.170.143.251');
UPDATE coachprofiles SET certificateUrl = REPLACE(certificateUrl, 'https://sirvya-1c5de0abe34c.herokuapp.com', 'http://51.170.143.251');
UPDATE coachimages SET urlImage = REPLACE(urlImage, 'https://sirvya-1c5de0abe34c.herokuapp.com', 'http://51.170.143.251');
