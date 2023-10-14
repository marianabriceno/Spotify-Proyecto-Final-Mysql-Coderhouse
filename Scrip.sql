CREATE SCHEMA New_DB_Spotify;

USE New_DB_Spotify;

	-- Tabla donde van registrados los artists con su noombre y año de debut
CREATE TABLE Artists (
    Artist_Id INT PRIMARY KEY,
    Name_Artist VARCHAR (100),
	Year_Debut YEAR
    
);

	-- Tabla que registra los id y los tipos de generos musicales
CREATE TABLE Genres (
    Genre_Id INT PRIMARY KEY,
    Genre_type VARCHAR (100)
    
   );
   
	-- Tabla que registra los datos de  los albumes de los artistas los id's, los titulos, numero de canciones del album, año y genero
CREATE TABLE Albums (
   Album_Id INT PRIMARY KEY,
    Title VARCHAR(100),
    Number_of_songs INT,
    Artist_Id INT,
    Release_Year YEAR,
    Genre_Id INT,
    FOREIGN KEY (Artist_Id) REFERENCES Artists(Artist_Id),
    FOREIGN KEY (Genre_Id) REFERENCES Genres(Genre_Id)
    
);

	-- Tabla que registra las canciones mas reproducidas de los interpretes y el album en el que aparece
CREATE TABLE Most_played_songs (
	Song_Id INT PRIMARY KEY,
    Title VARCHAR(200),
    Album_Id INT,
    Duration TIME,
    Genre_Id INT,
    Reproductions BIGINT,
    Artist_Id INT,
    FOREIGN KEY (Album_Id) REFERENCES Albums(Album_Id),
    FOREIGN KEY (Genre_Id) REFERENCES Genres(Genre_Id),
    FOREIGN KEY (Artist_Id) REFERENCES artists (Artist_Id)
    
);

	-- Tabla que registra los usuarios y su numero de playlist creadas
CREATE TABLE Users (
    User_Id INT PRIMARY KEY,
    User_Name VARCHAR(100),
    Numbers_Playlist INT
);

	-- Tabla para registrar las listas de reproducciones donde aparecen los artistas
CREATE TABLE Playlist (
    Playlist_Id INT PRIMARY KEY,
    User_Id INT,
    Name_of_playlist VARCHAR(100),
    Number_songs INT,
    FOREIGN KEY (User_Id) REFERENCES Users(User_Id)
);

	-- Tabla que registra los oyentes mensuales de los artistas en los plaaformas
CREATE TABLE Monthly_Listener (
	Listeners_Id INT PRIMARY KEY,
    Artist_Id INT,
    Name_artist VARCHAR(100), 
    Number_listeners INT,
    FOREIGN KEY (Artist_Id) REFERENCES Artists(Artist_Id)
    
);

-- log para EL REGISTRO de los disparadores 
CREATE TABLE Trigger_Log (
    Log_Id INT AUTO_INCREMENT PRIMARY KEY,
    Trigger_Name VARCHAR(100),
    Action VARCHAR(10),
    TableName VARCHAR(100),
    Record_Id INT,
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- tabla espejo de oyentes mensuales para hacer el update de los datos
CREATE TABLE IF NOT EXISTS Monthly_Listener_Espejo (

    Listeners_Id INT PRIMARY KEY,
    Artist_Id INT,
    Name_artist VARCHAR(100),
    Number_listeners BIGINT,
    FOREIGN KEY (Artist_Id) REFERENCES Artists(Artist_Id)
);

-- CONSULTAS DE DATOS

-- Esta consulta te proporcionará los nombres de los artistas, los títulos de las canciones, las reproducciones y los oyentes mensuales para el artista con el nombre 

SELECT 
    a.Name_Artist,
    mps.Title AS Title,
    mps.Reproductions,
    ml.Number_listeners AS Monthly_Listeners
FROM Artists a
        JOIN Most_Played_Songs mps ON a.Artist_Id = mps.Artist_Id
        JOIN Monthly_Listener ml ON a.Artist_Id = ml.Artist_Id
WHERE a.Name_Artist = 'Wu tang clan'; -- PUEDE HACER CONSULTA CON CUALQUIER INTERPRETE REGISTRADO EN LA DB
    
-- Esta consulta es para actualizar el número de oyentes mensuales (Monthly_Listeners) de un artista en la base de datos.

UPDATE Monthly_Listener 
SET Number_listeners = '270958'
WHERE Artist_Id = '9';

SELECT * FROM monthly_listener;
    
-- Esta consulta mostrará los artistas junto con sus oyentes mensuales los ordenará de menor a mayor número de oyentes mensuales.

SELECT a.Name_Artist, ml.Number_listeners
FROM artists a
	LEFT JOIN monthly_listener ml ON a.Artist_Id = ml.Artist_Id
	ORDER BY ml.Number_listeners ASC;

-- VISTAS
--  vista para los títulos de los álbumes, número de canciones del álbum y año de lanzamiento 
CREATE OR REPLACE VIEW Vista_Albums AS

SELECT Title, Number_of_songs, Release_Year
FROM Albums;

-- Vista para usuarios con mas listas de reproducciones creadas
CREATE OR REPLACE VIEW Vista_Usuarios_Con_Mas_Playlists AS

SELECT u.User_Id, u.Numbers_Playlist AS Numbers_Playlist, p.Name_of_playlist 
FROM Users u
 LEFT JOIN Playlist p ON u.User_Id = p.User_Id
 ORDER BY Numbers_Playlist DESC;

-- vista para interpretes por oyentes mensuales 
CREATE OR REPLACE VIEW vista_artistas_por_oyentes_mensuales AS
SELECT a.Artist_Id, a.Name_Artist, ml.Number_listeners AS Oyentes_Mensuales
FROM Artists a
	LEFT JOIN Monthly_Listener ml ON a.Artist_Id = ml.Artist_Id
	ORDER BY Oyentes_Mensuales;

-- vista que muestra los títulos de las canciones más reproducidas con el género
CREATE OR REPLACE VIEW Vista_Most_Played_Songs_Genres AS
SELECT mps.Song_Id, mps.Title AS Title_Song, g.Genre_type AS Genre
FROM Most_played_songs mps
	INNER JOIN Genres g ON mps.Genre_Id = g.Genre_Id;
    
-- STORE PROCEDURE

-- Obtiene las canciones, su género y las reproducciones.
DELIMITER //

CREATE PROCEDURE `PlayedSongs_ByGenre`(IN nombre_genero VARCHAR(100))
BEGIN
    SELECT MPS.Title, G.Genre_type, MPS.Reproductions
    FROM most_played_songs MPS
    INNER JOIN genres G ON MPS.Genre_Id = G.Genre_Id
    WHERE G.Genre_type = nombre_genero;
END;
//

DELIMITER ;

--  SP para inserta un nuevo usuario, nombre de la playlist y el número de canciones
DELIMITER //
CREATE PROCEDURE InsertNewUserAndPlaylist(
    IN in_user_id INT,
    IN in_user_name VARCHAR(100),
    IN in_playlist_name VARCHAR(100),
    IN in_number_songs INT
)
BEGIN
DECLARE user_count INT;
    SELECT COUNT(*) INTO user_count
    FROM Users
    WHERE User_Id = in_user_id;

    IF user_count = 0 THEN
        INSERT INTO Users (User_Id, User_Name)
        VALUES (in_user_id, in_user_name);
    END IF;

    -- Insertar la nueva playlist
    INSERT INTO Playlist (User_Id, Name_of_playlist, Number_songs)
    VALUES (in_user_id, in_playlist_name, in_number_songs);
END;
//
DELIMITER ;

-- TRIGGERS
-- Se crea un trigger para hacer un after update en la tabla monthly listener 
DELIMITER //
CREATE TRIGGER monthly_listener_After_update
AFTER UPDATE ON Monthly_Listener
FOR EACH ROW
BEGIN
    INSERT INTO Monthly_Listener_Espejo (Listeners_Id, Name_artist, Number_listeners)
    VALUES (NEW.Listeners_Id, NEW.Name_artist, NEW.Number_listeners);
    
    -- Registra en la tabla de log
    INSERT INTO Trigger_Log (Trigger_Name, Action, TableName, Record_Id)
    VALUES ('monthly_listener', 'UPDATE', 'Monthly_Listener', NEW.Listeners_Id);
END;
//
DELIMITER ;

-- se hace un update en la tabla monthly_listener para verificar que funcione el trigger
UPDATE Monthly_Listener
SET Artist_Id = 'ID DEL ARTISTA',
    Name_artist = 'NOMBRE DEL ARTISTA ACA',
    Number_listeners = 'SE AGREGA EL DATO'
WHERE Listeners_Id = 'ID DEL OYENTE';

-- se crea un el trigger para after delete de datos sobre la tabla albums
DELIMITER //
CREATE TRIGGER trigger_albums_before_delete
BEFORE DELETE ON Albums
FOR EACH ROW
BEGIN
    -- Insertar información en la tabla de registro antes de la eliminación
    INSERT INTO Trigger_Log (Trigger_Name, Action, TableName, Record_Id)
    VALUES ('trigger_albums_before_delete', 'DELETE', 'Albums', OLD.Album_Id);
END;
//
DELIMITER ;

-- Se hara un delete en la tabla de albumes para verificar que el trigger funcione correctamente y no sin antes desactivar la foreing key temporalmente para poder hacer el delete.
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM albums
WHERE Album_Id = -- ID DEL ALBUM
AND Title = 'NOMBRE DEL ALBUM'
AND Artist_Id = -- ID DEL ARTISTA;

-- FUNCIONES
-- número de usuarios registrados en la DDBB
DELIMITER //

CREATE FUNCTION ContarUsuariosRegistrados() 
    RETURNS INT 
    DETERMINISTIC
BEGIN
    DECLARE TotalUsuarios INT;
		SET TotalUsuarios = 0;

    -- se hizo selecet para contar el número de usuarios en la tabla
    SELECT COUNT(*) INTO TotalUsuarios
    FROM Users;

RETURN TotalUsuarios;
END;
//
DELIMITER ;

-- Promedio de los albums mayor a 2012
DELIMITER //

CREATE FUNCTION Promedio_Albums_Release () 
    RETURNS INT
    DETERMINISTIC
    
BEGIN
    DECLARE Promedio INT; 
    
    -- Calculo del promedio de lanzamientos anuales mayor a 2012
    SELECT AVG(AlbumsPorAño) INTO Promedio
    FROM (SELECT COUNT(*) AS AlbumsPorAño
          FROM albums
          WHERE Release_Year > 2012
          GROUP BY Release_Year) AS AlbumesPorAño;
    
RETURN Promedio;
END //

DELIMITER ;

-- esta funcion devuelve el total de la columna "number_songs"
DELIMITER //
CREATE FUNCTION Total_Number_Songs_En_Playlist() 
    RETURNS INT 
    DETERMINISTIC
BEGIN
    DECLARE Total_Number_Songs INT;

    -- Inicializar la variable
    SET Total_Number_Songs = 0;

    -- Obtener el total de la columna "number_songs" en la tabla "Playlist"
    SELECT SUM(number_songs) 
    INTO Total_Number_Songs
    FROM Playlist;

    -- Devolver el total de la columna "number_songs"
    RETURN Total_Number_Songs;
END;
//
DELIMITER ;

