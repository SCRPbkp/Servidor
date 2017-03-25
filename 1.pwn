//====================================================================================================================================================================================//

//																			L   I  B  R  E  R  I  A  S

//====================================================================================================================================================================================//


#include 	<a_samp>
#include 	<a_mysql>
#include 	<izcmd>
#include 	<sscanf2>
#include 	<foreach>
#include <streamer>

//====================================================================================================================================================================================//

//                                                                          V  A  R  I  A  B  L  E  S

//====================================================================================================================================================================================//

#define strcpy(%0,%1,%2) strcat((%0[0] = '\0', %0), %1, %2)
// ---------- MySQL --------------------//
#define		MYSQL_HOST 			"localhost"
#define		MYSQL_USER 			"root"
#define 	MYSQL_PASSWORD 		""
#define		MYSQL_DATABASE 		"servidor samp"
//---------- Posición default ---------//
#define 	DEFAULT_POS_X 		313.0305
#define 	DEFAULT_POS_Y 		-1798.7963
#define 	DEFAULT_POS_Z 		4.5517
#define 	DEFAULT_POS_A 		266.8596
//--------- Colores ----------------//
#define COL_PURPURA 0xB60597FF
#define COLOR_GRAD2 0xBFC0C2FF
#define COLOR_FADE 0xE6E6E6E6
#define COLOR_FADE1 0xE6E6E6E6
#define COLOR_FADE2 0xC8C8C8C8
#define COLOR_FADE3 0xAAAAAAAA
#define COLOR_FADE4 0x8C8C8C8C
#define COLOR_FADE5 0x6E6E6E6E
#define COL_CRIMSON 0xCC2538FF
#define COL_ROJO 0xAA3333AA
#define COL_VERDEAQUA 0x408080FF
#define COL_VERDEPASTEL 0x79FF79FF
#define COL_CELESTEPASTEL 0x88D9FFFF
#define COL_AMARILLOVIEJO 0xF5F6CEFF
#define COL_VERDEOSCURO 0x088A08FF
//------------Colores Admin ------------//

#define VERDE_ADMIN 0x7CC532FF
#define AMARILLO_ADMIN 0xFFFF00FF
#define CREMA_ADMIN 0xFFFF9FFF
#define ORANGE_ADMIN 0xFF8000FF
#define CELESTE_ADMIN 0x0080C0FF
#define PURPURA_ADMIN 0xB932B9FF
#define COLOR_ADM      17
#define COL_GRIS 0x808080FF
//---------Mensajes------------//
#define 			NODUTY        				"* No puedes usar este comando porque no estas en servicio administrativo (/aduty)."
#define 			NoAutorizado        		SendClientMessage(playerid, COL_CRIMSON,"No estás autorizado para usar este comando!");

#define     SECONDS_TO_LOGIN     30

new MySQL: g_SQL;

// --- Sistema de Spawn --- //
new PrimerSpawn[MAX_PLAYERS];
new szMessage[128];



//====================================================================================================================================================================================//

//                                                                          E N U M S

//====================================================================================================================================================================================//


enum E_JUGADORES
{
	ID,
	Name[MAX_PLAYER_NAME],
	Password[65], // the output of SHA256_PassHash function (which was added in 0.3.7 R1 version) is always 256 bytes in length, or the equivalent of 64 Pawn cells
	Salt[17],
	Float: X_Pos,
	Float: Y_Pos,
	Float: Z_Pos,
	Float: A_Pos,
	Interior,
	bool: IsLoggedIn,
	LoginAttempts,
	LoginTimer,
	Cache: Cache_ID,
	pSkin,
	pAdmin,
	Float: pSalud,
	Float: pChaleco,
	pDinero,
	pNivel,
	pExp,
	pPrimerLog,
	pMinPayday,
	pSexo,
	pEdad,
	pRaza,
 	pAdminDuty,
 	pAdminLvl,
 	pFrozen,
 	pVirtualWorld,
 	pSpectating,
 	bool: isAlive,
 	pFaccion,
 	pRango,
 	pDNI
};
new pInfo[MAX_PLAYERS][E_JUGADORES];
new g_MysqlRaceCheck[MAX_PLAYERS];
new gBcmd[MAX_PLAYERS];
new Nacionalidad[50];
new BigEar[MAX_PLAYERS];
enum
{
	DIALOG_UNUSED,
	DIALOG_LOGIN,
	DIALOG_REGISTER,
	DIALOG_SEXO,
	DIALOG_EDAD,
	DIALOG_NACIONALIDAD,
	DIALOG_FNOMBRE,
	DIALOG_FTIPO,
	DIALOG_FRANGO1,
	DIALOG_FRANGO2,
	DIALOG_FRANGO3,
	DIALOG_FRANGO4,
	DIALOG_FRANGO5,
	DIALOG_FRANGO6,
	DIALOG_FRANGO7
};

/*new Levels[7][24] =
{
    {
        "Moderador Jr"
    },
    {
        "Moderador Avanzado"
    },
    {
        "Administrador Junior"
    },
    {
        "Administrador Semi-Senior"
    },
    {
        "Administrador Senior"
    },
    {
        "Encargado"
    },
    {
        "Administrador Dueño"
    }
}; */

new AdminChat[MAX_PLAYERS];
new deadvw[MAX_PLAYERS];
new bool:stopanimAllowed[MAX_PLAYERS];

// -------- Facciones //
#define MAX_FACTIONS 30
enum faccionesInfo
{
	fID,
	fNombre,
	fRango1,
	fRango2,
	fRango3,
	fRango4,
	fRango5,
	fRango6,
	fRango7,
	fTipo,
	fLider
};
new fInfo[MAX_FACTIONS][faccionesInfo];
new NombreFaccion[128];
new FaccionTipo;
new ftRango1[30];
new ftRango2[30];
new ftRango3[30];
new ftRango4[30];
new ftRango5[30];
new ftRango6[30];
new ftRango7[30];
new TotalFaccs;
//====================================================================================================================================================================================//

//                                                                          CALLBACKS

//====================================================================================================================================================================================//

main() {}



public OnGameModeInit()
{
	new MySQLOpt: option_id = mysql_init_options();
    mysql_log(ALL);
	mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id); // AUTO_RECONNECT is enabled for this connection handle only
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("MySQL connection failed. Server is shutting down.");
		SendRconCommand("exit"); // close the server if there is no connection
		return 1;
	}

	LoadFaccs();
	print("MySQL connection is successful.");
    ShowPlayerMarkers(false);
    SetTimer("TimerDeUnMinuto",60000,1); //Inicia timer de un minuto
    SetTimer("TimerDeMedioSegundo",500,1);
	return 1;
}

public OnGameModeExit()
{
	// save all player data before closing connection
	for (new i = 0, j = GetPlayerPoolSize(); i <= j; i++) // GetPlayerPoolSize function was added in 0.3.7 version and gets the highest playerid currently in use on the server
	{
		if (IsPlayerConnected(i))
		{
		    // reason is set to 1 for normal 'Quit'
			OnPlayerDisconnect(i, 1);
		}
	}

	mysql_close(g_SQL);

	SetTimer("PayDay",360000,1);// Payday cada 1 hora
	SetTimer("ScoreUpdate", 1000, 1); //No cambiar
	return 1;
}

public OnPlayerConnect(playerid)
{
	g_MysqlRaceCheck[playerid]++;

	// reset player data
	static const empty_player[E_JUGADORES];
	pInfo[playerid] = empty_player;
    pInfo[playerid][pSkin] = 0;
    SetPlayerColor(playerid, COLOR_GRAD2);
	GetPlayerName(playerid, pInfo[playerid][Name], MAX_PLAYER_NAME);

	// send a query to recieve all the stored player data from the table
	new query[103];
	mysql_format(g_SQL, query, sizeof query, "SELECT * FROM `jugadores` WHERE `username` = '%e' LIMIT 1", pInfo[playerid][Name]);
	mysql_tquery(g_SQL, query, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);



	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	g_MysqlRaceCheck[playerid]++;
	UpdatePlayerData(playerid);
	// if the player was kicked (either wrong password or taking too long) during the login part, remove the data from the memory
	if (cache_is_valid(pInfo[playerid][Cache_ID]))
	{
		cache_delete(pInfo[playerid][Cache_ID]);
		pInfo[playerid][Cache_ID] = MYSQL_INVALID_CACHE;
	}

	// if the player was kicked before the time expires (30 seconds), kill the timer
	if (pInfo[playerid][LoginTimer])
	{
		KillTimer(pInfo[playerid][LoginTimer]);
		pInfo[playerid][LoginTimer] = 0;
	}

	// sets "IsLoggedIn" to false when the player disconnects, it prevents from saving the player data twice when "gmx" is used
	pInfo[playerid][pSkin] = GetPlayerSkin(playerid);
	pInfo[playerid][IsLoggedIn] = false;
	return 1;
}



public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_UNUSED: return 1; // Useful for dialogs that contain only information and we do nothing depending on whether they responded or not

        case DIALOG_LOGIN:
        {
            if (!response) return Kick(playerid);

            new hashed_pass[65];
            SHA256_PassHash(inputtext, pInfo[playerid][Salt], hashed_pass, 65);

            if (strcmp(hashed_pass, pInfo[playerid][Password]) == 0)
            {
                //correct password, spawn the player
                ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "You have been successfully logged in.", "Okay", "");

                // sets the specified cache as the active cache so we can retrieve the rest player data
                cache_set_active(pInfo[playerid][Cache_ID]);

                AssignPlayerData(playerid);

                // remove the active cache from memory and unsets the active cache as well
                cache_delete(pInfo[playerid][Cache_ID]);
                pInfo[playerid][Cache_ID] = MYSQL_INVALID_CACHE;

                KillTimer(pInfo[playerid][LoginTimer]);
                pInfo[playerid][LoginTimer] = 0;
                pInfo[playerid][IsLoggedIn] = true;

				GivePlayerMoney(playerid, pInfo[playerid][pDinero]);
				SetPlayerScore(playerid, pInfo[playerid][pNivel]);
				// spawn the player to their last saved position after login
				SetSpawnInfo(playerid, NO_TEAM, 0, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos], pInfo[playerid][A_Pos], 0, 0, 0, 0, 0, 0);
                SpawnPlayer(playerid);
            }
            else
            {
                pInfo[playerid][LoginAttempts]++;

                if (pInfo[playerid][LoginAttempts] >= 3)
                {
                    ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "You have mistyped your password too often (3 times).", "Okay", "");
                    DelayedKick(playerid);
                }
                else ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Wrong password!\nPlease enter your password in the field below:", "Login", "Abort");
            }
        }
        case DIALOG_REGISTER:
        {
            if (!response) return Kick(playerid);

            if (strlen(inputtext) <= 5) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{CC2538}REGISTRO:{FFFFFF}", "{FFFFFF}Tu contraseña debe tener más de 5 caracteres\nPor favor, ingresá la contraseña:", "Register", "Abort");
            GivePlayerMoney(playerid, 10000);

            // 16 random characters from 33 to 126 (in ASCII) for the salt
            for (new i = 0; i < 16; i++) pInfo[playerid][Salt][i] = random(94) + 33;
            SHA256_PassHash(inputtext, pInfo[playerid][Salt], pInfo[playerid][Password], 65);       	
        	
        	
            new str[38+1];
			format(str, sizeof(str), "%s{FFFFFF}Define el sexo de tu personaje", str);
			ShowPlayerDialog(playerid, DIALOG_SEXO, DIALOG_STYLE_MSGBOX, "{CC2538}REGISTRO:{FFFFFF}SEXO", str, "Masculino", "Femenino");


        }

        case DIALOG_SEXO:
        {
            if (response == 1)
            {

				pInfo[playerid][pSexo] = 1;
				new str[90+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresa la edad de tu personaje (tené en cuenta que el personaje cumplirá años IC)", str);
				ShowPlayerDialog(playerid, DIALOG_EDAD, DIALOG_STYLE_INPUT, "{CC2538}REGISTRO:{FFFFFF}EDAD", str, "Aceptar", "Cancelar");


            }

            else
			{
       			pInfo[playerid][pSexo] = 2;
				new str[90+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresa la edad de tu personaje (tené en cuenta que el personaje cumplirá años IC)", str);
				ShowPlayerDialog(playerid, DIALOG_EDAD, DIALOG_STYLE_INPUT, "{CC2538}REGISTRO:{FFFFFF}EDAD", str, "Aceptar", "Cancelar");


            }
        }

        case DIALOG_EDAD:
        {
            if(strval(inputtext) < 18 || strval(inputtext) > 78) return ShowPlayerDialog(playerid, DIALOG_EDAD, DIALOG_STYLE_INPUT, "{CC2538}REGISTRO:{FFFFFF}EDAD", "{CC2538}¡ATENCIÓN!\n{FFFFFF} La edad mínima es 18 y la máxima 78.","Aceptar","");
			if(strval(inputtext) > 18 || strval(inputtext) < 90)
			{

			    pInfo[playerid][pEdad] = strval(inputtext);
			    new string[90];
			    format(string, sizeof(string), "{FFFFFF}Norteamericano\nLatino\nEuropeo\nAfroamericano\nAsiático\nOriental\nÁrabe");
	       	    ShowPlayerDialog(playerid, DIALOG_NACIONALIDAD, DIALOG_STYLE_LIST, "{CC2538}REGISTRO:{FFFFFF}RAZA",string, "Ok", "");
			}
        }

        case DIALOG_NACIONALIDAD:
        {
            switch(listitem)
                    {
						case 0:
                        {    

                        	//"Norteamericano"							
							pInfo[playerid][pRaza] = 1; 
							pInfo[playerid][pDNI] = random(999999);                      
		       				GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);		       						       				    				
		       				new query[500];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%i')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);							
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);


                        }
                        case 1:
                        {

                            //"Latino"
							pInfo[playerid][pRaza] = 2; 
							pInfo[playerid][pDNI] = random(999999);
		        			GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);
		        			
		        			new query[270];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%d')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);


                        }
                        case 2:
                        {

                            //"Europeo"
							pInfo[playerid][pRaza] = 3; 
							pInfo[playerid][pDNI] = random(999999);
		        			GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);
		        			new query[270];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%d')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);


                        }
                        case 3:
                        {

                            //"Afroamericano";
							pInfo[playerid][pRaza] = 4; 
							pInfo[playerid][pDNI] = random(999999);
		        			GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);
		        			new query[270];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%d')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);


                        }
                        case 4:
                        {

                            // "Asiático";
							pInfo[playerid][pRaza] = 5; 
							pInfo[playerid][pDNI] = random(999999);
		       				GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);
		       				new query[270];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%d')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);


                        }
                        case 5:
                        {

                            //"Oriental"
							pInfo[playerid][pRaza] = 6; 
							pInfo[playerid][pDNI] = random(999999);
                            GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);
                            new query[270];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%d')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);

                        }
                        case 6:
                        {

                            // "Árabe"
							pInfo[playerid][pRaza] = 7; 
							pInfo[playerid][pDNI] = random(999999);
		       				GameTextForPlayer(playerid, "~R~Bienvenido a la ciudad del pecado", 1500, 3);
		       				new query[270];
				            mysql_format(g_SQL, query, sizeof query, "INSERT INTO `jugadores` (`username`, `password`, `salt`, `pSexo`, `pEdad`, `pRaza`, `pDNI`) VALUES ('%e', '%s', '%e', '%i', '%i', '%i', '%d')", pInfo[playerid][Name], pInfo[playerid][Password], pInfo[playerid][Salt],
							pInfo[playerid][pSexo], pInfo[playerid][pEdad], pInfo[playerid][pRaza], pInfo[playerid][pDNI]);
				            mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);

                        }

				   }
		}

		case DIALOG_FNOMBRE:
		{
			if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60) {
			format(NombreFaccion, sizeof(NombreFaccion), "%s", inputtext);
			new str[37+1];
			format(str, sizeof(str), "%s{FFFFFF}Selecciona el tipo de facción", str);
			ShowPlayerDialog(playerid, DIALOG_FTIPO, DIALOG_STYLE_MSGBOX, "{CC2538}CREAR FACCION:{FFFFFF} TIPO DE FACCION", str, "Legal", "Ilegal");
			}
		}

		case DIALOG_FTIPO:
        {
			if (response == 1)
			{
			FaccionTipo = 1;
			new str[37+1];
			format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 1", str);
			ShowPlayerDialog(playerid, DIALOG_FRANGO1, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
			else {
			FaccionTipo = 2;
			new str[37+1];
			format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 1", str);
			ShowPlayerDialog(playerid, DIALOG_FRANGO1, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO1:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango1, sizeof(ftRango1), "%s", inputtext);
				new str[37+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 2", str);
				ShowPlayerDialog(playerid, DIALOG_FRANGO2, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO2:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango2, sizeof(ftRango2), "%s", inputtext);
				new str[37+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 3", str);
				ShowPlayerDialog(playerid, DIALOG_FRANGO3, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO3:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango3, sizeof(ftRango3), "%s", inputtext);
				new str[37+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 4", str);
				ShowPlayerDialog(playerid, DIALOG_FRANGO4, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO4:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango4, sizeof(ftRango4), "%s", inputtext);
				new str[37+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 5", str);
				ShowPlayerDialog(playerid, DIALOG_FRANGO5, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO5:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango5, sizeof(ftRango5), "%s", inputtext);
				new str[37+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 6", str);
				ShowPlayerDialog(playerid, DIALOG_FRANGO6, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO6:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango6, sizeof(ftRango6), "%s", inputtext);
				new str[37+1];
				format(str, sizeof(str), "%s{FFFFFF}Ingresá el nombre del Rango 7", str);
				ShowPlayerDialog(playerid, DIALOG_FRANGO7, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION: {FFFFFF}RANGOS", str, "Aceptar", "Cancelar");
			}
        }

        case DIALOG_FRANGO7:
        {
        	if(strlen(inputtext) == 0) return ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION", "{CC2538}¡ATENCIÓN!\n{FFFFFF} No ingresaste texto","Aceptar","");
			if(strlen(inputtext) < 60)
			{
				format(ftRango7, sizeof(ftRango7), "%s", inputtext);
                new query[270];
				mysql_format(g_SQL, query, sizeof query, "INSERT INTO `facciones` (`fNombre`, `fTipo`, `fRango1`, `fRango2`, `fRango3`, `fRango4`, `fRango5`, `fRango6`, `fRango7`) VALUES ('%s', '%d', '%s', '%e', '%e', '%e', '%e', '%e', '%e')",
				NombreFaccion, FaccionTipo, ftRango1, ftRango2, ftRango3, ftRango4, ftRango5, ftRango6, ftRango7);
	            mysql_tquery(g_SQL, query);
	            new str[92+1];
				format(str, sizeof(str), "%s{FFFFFF}La facción fue creada correctamente. Para verificar, usar el comando /listafacciones", str);
				ShowPlayerDialog(playerid, 4541, DIALOG_STYLE_MSGBOX, "{CC2538}CREAR FACCION", str, "Accept", "");

			}
        }
	}
	return 1;
}



forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	// retrieves the ID generated for an AUTO_INCREMENT column by the sent query
	pInfo[playerid][ID] = cache_insert_id();
	pInfo[playerid][X_Pos] = DEFAULT_POS_X;
	pInfo[playerid][Y_Pos] = DEFAULT_POS_Y;
	pInfo[playerid][Z_Pos] = DEFAULT_POS_Z;
	pInfo[playerid][A_Pos] = DEFAULT_POS_A;

	if(pInfo[playerid][pSexo] == 1) {
		SetPlayerSkin(playerid, 96);
		pInfo[playerid][pSkin] = 96;
	}
	if(pInfo[playerid][pSexo] == 2) {
		SetPlayerSkin(playerid, 192);
		pInfo[playerid][pSkin] = 192;
	}
	SetPlayerHealth(playerid, 100);
    pInfo[playerid][pAdmin] = 0;
    pInfo[playerid][pSalud] = 100;
    pInfo[playerid][pNivel] = 1;
    pInfo[playerid][pExp] = 0;
    SetSpawnInfo(playerid, NO_TEAM, 0, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos], pInfo[playerid][A_Pos], 0, 0, 0, 0, 0, 0);
	pInfo[playerid][IsLoggedIn] = true;	
	pInfo[playerid][pFaccion] = 0;
	pInfo[playerid][pRango] = 0;
	pInfo[playerid][isAlive] = true;
			
	SpawnPlayer(playerid);
	return 1;

}




public OnPlayerSpawn(playerid)
{
    PreloadAnimLib(playerid,"BOMBER");
	PreloadAnimLib(playerid,"RAPPING");
	PreloadAnimLib(playerid,"SHOP");
	PreloadAnimLib(playerid,"BEACH");
	PreloadAnimLib(playerid,"SMOKING");
	PreloadAnimLib(playerid,"FOOD");
	PreloadAnimLib(playerid,"ON_LOOKERS");
	PreloadAnimLib(playerid,"DEALER");
	PreloadAnimLib(playerid,"CRACK");
	PreloadAnimLib(playerid,"CARRY");
	PreloadAnimLib(playerid,"COP_AMBIENT");
	PreloadAnimLib(playerid,"PARK");
	PreloadAnimLib(playerid,"INT_HOUSE");
	PreloadAnimLib(playerid,"FOOD" );
	PreloadAnimLib(playerid,"PED" );
	// spawn the player to their last saved position

	SetPlayerInterior(playerid, pInfo[playerid][Interior]);
	SetPlayerPos(playerid, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos]);
	SetPlayerFacingAngle(playerid, pInfo[playerid][A_Pos]);
    SetPlayerSkin(playerid, pInfo[playerid][pSkin]);
	SetCameraBehindPlayer(playerid);
 	SetPlayerHealth(playerid, pInfo[playerid][pSalud]);
 	SetPlayerArmour(playerid, pInfo[playerid][pChaleco]);

	if(pInfo[playerid][isAlive] == false)
		{
		    SetPlayerPos(playerid, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos]);
		    SetPlayerInterior(playerid, pInfo[playerid][Interior]);
		    SetPlayerVirtualWorld(playerid, deadvw[playerid]);
			stopanimAllowed[playerid] = false;
		    SendClientMessage(playerid, ORANGE_ADMIN, "Actualmente estás herido. Si nadie te ayuda morirás, podés aceptar tu destino escribiendo /aceptarmuerte.");
	     	TogglePlayerControllable(playerid,0);
	 	    SetTimerEx("LoadDeathAnim", 1000, false, "i", playerid);
    		SetPlayerSkin(playerid, pInfo[playerid][pSkin]);
		}


    switch(pInfo[playerid][pAdmin])
	{
	case 1:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Junior", string);
	    }
	case 2:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Semi-senior", string);
	    }
	case 3:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Senior", string);
	    }
	case 4:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Experto", string);
	    }
	case 5:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Global", string);
	    }
	case 6:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Encargado", string);
	    }
	case 7:
	    {
	        new string[24];
	        format(pInfo[playerid][pAdminLvl], sizeof(string), "Dueño", string);
	    }
	}

	switch(pInfo[playerid][pRaza])
	{
		case 1:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Norteamericano", Nacionalidad);
		}
		case 2:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Latino", Nacionalidad);
		}
		case 3:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Europeo", Nacionalidad);
		}
		case 4:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Afroamericano", Nacionalidad);
		}
		case 5:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Asiatico", Nacionalidad);
		}
		case 6:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Oriental", Nacionalidad);
		}
		case 7:
		{
			format(Nacionalidad, sizeof(Nacionalidad), "Arabe", Nacionalidad);
		}
	}



	return 1;
}


public OnPlayerDeath(playerid, killerid, reason)
{
    GetPlayerPos(playerid, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos]);
	pInfo[playerid][Interior] = GetPlayerInterior(playerid);
	deadvw[playerid] = GetPlayerVirtualWorld(playerid);
	pInfo[playerid][pSkin] = GetPlayerSkin(playerid);
	GivePlayerMoney(playerid, 100);
 	pInfo[playerid][isAlive] = false;
}

public OnPlayerText(playerid, text[])
{
    new message[128];
    format(message, sizeof(message), "%s dice: %s", NombreJugador(playerid), text);
    ProxDetectorEx(30.0, playerid, message, -1);
	return 0;
}

forward LoadDeathAnim(playerid);
public LoadDeathAnim(playerid)
{
	ApplyPlayerAnimation(playerid, "CRACK", "CRCKIDLE2", 4.0, 1, 0, 0, 0, 0, 1);
	return 1;
}

stock ApplyPlayerAnimation(playerid, animlib[], animname[], Float:fDelta, loop, lockx, locky, freeze, time, forcesync = 0)
{
    ApplyAnimation(playerid, animlib, "null", fDelta, loop, lockx, locky, freeze, time, forcesync); // Pre-load animation library
    return ApplyAnimation(playerid, animlib, animname, fDelta, loop, lockx, locky, freeze, time, forcesync);
}

forward StockAceptarMuerte(playerid);
public StockAceptarMuerte(playerid)
{
    SendClientMessage(playerid, COL_CRIMSON, "Llegaste inconsciente al hospital, se te realizó una operación y sobreviviste.");
    SendClientMessage(playerid, COL_CRIMSON, "Por costos de operación se te descontó $150.");
    SetPlayerPos(playerid, 1188.2881,-1323.6527,13.5668);
    SetPlayerFacingAngle(playerid,271.3262);
    TogglePlayerControllable(playerid,1);
 	pInfo[playerid][isAlive] = true;
 	ClearAnimations(playerid);
 	GivePlayerMoney(playerid, -150);
 	return 1;
}

forward StockAceptarMuerteAnim(playerid);
public StockAceptarMuerteAnim(playerid)
{
    ApplyAnimation(playerid, "PED", "KO_shot_front",4.1,0,1,1,1,1);
}

forward OnPlayerDataLoaded(playerid, race_check);
public OnPlayerDataLoaded(playerid, race_check)
{
    /*	race condition check:
        player A connects -> SELECT query is fired -> this query takes very long
        while the query is still processing, player A with playerid 2 disconnects
        player B joins now with playerid 2 -> our laggy SELECT query is finally finished, but for the wrong player

        what do we do against it?
        we create a connection count for each playerid and increase it everytime the playerid connects or disconnects
        we also pass the current value of the connection count to our OnPlayerDataLoaded callback
        then we check if current connection count is the same as connection count we passed to the callback
        if yes, everything is okay, if not, we just kick the player
    */
    if (race_check != g_MysqlRaceCheck[playerid]) return Kick(playerid);

    new string[115];
    if(cache_num_rows() > 0)
    {
        // we store the password and the salt so we can compare the password the player inputs
        // and save the rest so we won't have to execute another query later
        cache_get_value(0, "password", pInfo[playerid][Password], 65);
        cache_get_value(0, "salt", pInfo[playerid][Salt], 17);

        // saves the active cache in the memory and returns an cache-id to access it for later use
        pInfo[playerid][Cache_ID] = cache_save();

        format(string, sizeof string, "{FFFFFF}Bienvenido de nuevo, %s. Por favor, ingresá tu contraseña para ingresar:", pInfo[playerid][Name]);
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{CC2538}LOGIN", string, "Login", "Abort");

        // from now on, the player has 30 seconds to login
        pInfo[playerid][LoginTimer] = SetTimerEx("OnLoginTimeout", SECONDS_TO_LOGIN * 1000, false, "d", playerid);
    }
    else
    {
        format(string, sizeof string, "{FFFFFF}Bienvenido %s, ingresa la contraseña que desees usar en el servidor:", pInfo[playerid][Name]);
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{CC2538}REGISTRO:{FFFFFF}CONTRASEÑA", string, "Aceptar", "Cancelar");
    }
    return 1;
}



forward OnLoginTimeout(playerid);
public OnLoginTimeout(playerid)
{
	// reset the variable that stores the timerid
	pInfo[playerid][LoginTimer] = 0;

	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "{CC2538}LOGIN", "{FFFFFF}Has sido kickeado del servidor por tardar demasiado en ingresar.", "Aceptar", "");
	DelayedKick(playerid);
	return 1;
}


forward _KickPlayerDelayed(playerid);
public _KickPlayerDelayed(playerid)
{
    Kick(playerid);
    return 1;
}




forward TimerDeUnMinuto(); //Timer que se activa cada minuto
public TimerDeUnMinuto()
{
    for(new playerid = 0; playerid < MAX_PLAYERS; playerid++) //Loop de playerids
	{
	    if(pInfo[playerid][IsLoggedIn] == true)
     	{
		    //Contador de activación de payday
		    pInfo[playerid][pMinPayday] ++;
		    if(pInfo[playerid][pMinPayday] >= 55)
		    {
		        pInfo[playerid][pMinPayday] = 0;
		        PayDay(playerid);
		    }
            //Reloj real
            new hora, minuto, segundo, ahora;
            gettime(hora, minuto, segundo);
            SetPlayerTime(playerid, hora+ahora, minuto);
            SetWorldTime(hora+ahora);
            //Marca hora preciso
        	if(minuto == 0 && segundo < 60 && segundo > 0)
        	{
        	    new string[30];
        	    format(string, sizeof(string), "Hora actual: %d:00", hora);
        	    SendClientMessage(playerid, -1, string);
     		}
	  	}
	}
 	return 1;

 }

AssignPlayerData(playerid)
{
	
    cache_get_value_int(0, "id", pInfo[playerid][ID]);
    cache_get_value_float(0, "PosX", pInfo[playerid][X_Pos]);
    cache_get_value_float(0, "PosY", pInfo[playerid][Y_Pos]);
    cache_get_value_float(0, "PosZ", pInfo[playerid][Z_Pos]);
    cache_get_value_float(0, "PosA", pInfo[playerid][A_Pos]);
    cache_get_value_int(0, "interior", pInfo[playerid][Interior]);
    cache_get_value_int(0, "pSkin", pInfo[playerid][pSkin]);
    cache_get_value_int(0, "pAdmin", pInfo[playerid][pAdmin]);
    cache_get_value_float(0, "pSalud", pInfo[playerid][pSalud]);
    cache_get_value_float(0, "pChaleco", pInfo[playerid][pChaleco]);
    cache_get_value_int(0, "pDinero", pInfo[playerid][pDinero]);
    cache_get_value_int(0, "pNivel", pInfo[playerid][pNivel]);
    cache_get_value_int(0, "pExp", pInfo[playerid][pExp]);
    cache_get_value_int(0, "pPrimerLog", pInfo[playerid][pPrimerLog]);
    cache_get_value_int(0, "pMinPayday", pInfo[playerid][pMinPayday]);
    cache_get_value_int(0, "pSexo", pInfo[playerid][pSexo]);
    cache_get_value_int(0, "pEdad", pInfo[playerid][pEdad]);
    cache_get_value_bool(0, "isAlive", pInfo[playerid][isAlive]);
    cache_get_value_int(0, "pRaza", pInfo[playerid][pRaza]);    
    cache_get_value_int(0, "pFaccion", pInfo[playerid][pFaccion]);
    cache_get_value_int(0, "pRango", pInfo[playerid][pRango]);
    cache_get_value_int(0, "pDNI", pInfo[playerid][pDNI]);
    
    return 1;
}

LoadFaccs()
{
	new sql[80], query[50];
	format(sql, sizeof(sql), "SELECT * FROM `facciones` WHERE `borradoLogico` = 0");
	mysql_query(g_SQL, sql);
	new rows;
	cache_get_row_count(rows);
	for(new i = 0, j = rows; i < j; i++){		
		cache_get_value_name(i, "fNombre", query);
		format(fInfo[i][fNombre], 60, "%s", query);
		cache_get_value_name(i, "fRango1", query);
		format(fInfo[i][fRango1], 30, "%s", query);
		cache_get_value_name(i, "fRango2", query);
		format(fInfo[i][fRango2], 30, "%s", query);
		cache_get_value_name(i, "fRango3", query);
		format(fInfo[i][fRango3], 30, "%s", query);
		cache_get_value_name(i, "fRango4", query);
		format(fInfo[i][fRango4], 30, "%s", query);
		cache_get_value_name(i, "fRango5", query);
		format(fInfo[i][fRango5], 30, "%s", query);
		cache_get_value_name(i, "fRango6", query);
		format(fInfo[i][fRango6], 30, "%s", query);
		cache_get_value_name(i, "fRango7", query);
		format(fInfo[i][fRango7], 30, "%s", query);
		cache_get_value_int(i, "fID", fInfo[i][fID]);
		cache_get_value_name(i, "fLider", query);
		format(fInfo[i][fLider], 64, "%s", query);
		if(TotalFaccs < i) TotalFaccs = i;
	}
	printf("Facciones cargadas: %d (MAX: %d)", TotalFaccs, MAX_FACTIONS);
}

SaveFaccs(faccid)
{
	new query[500];
	format(query, sizeof(query), "UPDATE facciones SET `fRango1` = '%s', `fRango2` = '%s', `fRango3` = '%s', `fRango4` = '%s', `fRango5` = '%s', `fRango6` = '%s', `fRango7` = '%s' WHERE `fID` = '%i'",
	fInfo[faccid][fRango1], fInfo[faccid][fRango2], fInfo[faccid][fRango3], fInfo[faccid][fRango4], fInfo[faccid][fRango5], fInfo[faccid][fRango6], fInfo[faccid][fRango7], fInfo[faccid][fLider], fInfo[faccid][fID]);
	mysql_query(g_SQL, query);	

	
	format(query, sizeof(query), "UPDATE facciones SET `fLider` = '%s' WHERE `fID` = '%i'",
	fInfo[faccid][fLider], fInfo[faccid][fID]);
	mysql_query(g_SQL, query);
}

DelayedKick(playerid, time = 500)
{
	SetTimerEx("_KickPlayerDelayed", time, false, "d", playerid);
	return 1;
}


UpdatePlayerData(playerid)
{
	GetPlayerPos(playerid, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos]);
	GetPlayerFacingAngle(playerid, pInfo[playerid][A_Pos]);
	GetPlayerHealth(playerid, pInfo[playerid][pSalud]);
	GetPlayerArmour(playerid, pInfo[playerid][pChaleco]);
	GetPlayerMoney(playerid);
	GetPlayerSkin(playerid);
	new query[1024];
	mysql_format(g_SQL, query, sizeof query, "UPDATE `jugadores` SET `PosX` = '%f', `PosY` = '%f', `PosZ` = '%f', `PosA` = '%f', `interior` = '%d', `pSalud` = '%f', `pChaleco` = '%f', `isAlive` = '%d', `pDinero` = '%d', `pSkin` = '%d', `pNivel` = '%d', `pExp` = '%d', `pPrimerLog` = '%d', `pFaccion` = '%d', `pRango` = '%d' WHERE `id` = '%d'",
	pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos], pInfo[playerid][A_Pos], GetPlayerInterior(playerid),
	pInfo[playerid][pSalud], pInfo[playerid][pChaleco], pInfo[playerid][isAlive], GetPlayerMoney(playerid), GetPlayerSkin(playerid), pInfo[playerid][pNivel], pInfo[playerid][pExp], 
	pInfo[playerid][pPrimerLog], pInfo[playerid][pFaccion], pInfo[playerid][pRango], pInfo[playerid][ID]);
	mysql_tquery(g_SQL, query);
    return 1;

}

forward PayDay(playerid);
public PayDay(playerid)
{
	if(PrimerSpawn[playerid] != 1){return 1;}
	UpdatePlayerData(playerid); //Guarda stats
	//Mensaje payday
	GameTextForPlayer(playerid, "~g~PAYDAY", 1000, 1);
	//Puntos de respeto y nivel
	new nivel = pInfo[playerid][pNivel];
	pInfo[playerid][pExp]++;
	GetPlayerLevel(playerid);

	if(pInfo[playerid][pNivel] > nivel)
	{
	    new string[50];
		format(string, sizeof(string), "~w~¡Ahora eres nivel ~g~%d~w~!", pInfo[playerid][pNivel]);
		GameTextForPlayer(playerid, string, 1000, 1);
	}
	return 1;
}



stock GetPlayerLevel(playerid) //Sube de nivel automáticamente
{
    new nivel = pInfo[playerid][pNivel], string[50];
	if(pInfo[playerid][pExp] >= 1110) pInfo[playerid][pNivel]=20;
	else if(pInfo[playerid][pExp] >= 990) pInfo[playerid][pNivel]=19;
	else if(pInfo[playerid][pExp] >= 870) pInfo[playerid][pNivel]=18;
	else if(pInfo[playerid][pExp] >= 750) pInfo[playerid][pNivel]=17;
	else if(pInfo[playerid][pExp] >= 630) pInfo[playerid][pNivel]=16;
	else if(pInfo[playerid][pExp] >= 510) pInfo[playerid][pNivel]=15;
	else if(pInfo[playerid][pExp] >= 450) pInfo[playerid][pNivel]=14;
	else if(pInfo[playerid][pExp] >= 390) pInfo[playerid][pNivel]=13;
	else if(pInfo[playerid][pExp] >= 330) pInfo[playerid][pNivel]=12;
	else if(pInfo[playerid][pExp] >= 270) pInfo[playerid][pNivel]=11;
	else if(pInfo[playerid][pExp] >= 210) pInfo[playerid][pNivel]=10;
	else if(pInfo[playerid][pExp] >= 180) pInfo[playerid][pNivel]=9;
	else if(pInfo[playerid][pExp] >= 150) pInfo[playerid][pNivel]=8;
	else if(pInfo[playerid][pExp] >= 120) pInfo[playerid][pNivel]=7;
	else if(pInfo[playerid][pExp] >= 90) pInfo[playerid][pNivel]=6;
	else if(pInfo[playerid][pExp] >= 60) pInfo[playerid][pNivel]=5;
	else if(pInfo[playerid][pExp] >= 45) pInfo[playerid][pNivel]=4;
	else if(pInfo[playerid][pExp] >= 30) pInfo[playerid][pNivel]=3;
	else if(pInfo[playerid][pExp] >= 15) pInfo[playerid][pNivel]=2;
	else if(pInfo[playerid][pExp] >= 0) pInfo[playerid][pNivel]=1;
	if(pInfo[playerid][pNivel] > nivel)
	{
		format(string, sizeof(string), "~w~¡Ahora eres nivel ~g~%d~w~!", pInfo[playerid][pNivel]);
		GameTextForPlayer(playerid, string, 1000, 1);
	}
	return pInfo[playerid][pNivel];
}

stock SetPlayerLevel(playerid) //Asigna pExp al nivel del jugador
{
	if(pInfo[playerid][pNivel] == 20) pInfo[playerid][pExp] = 1000;
	else if(pInfo[playerid][pNivel] == 19) pInfo[playerid][pExp] = 550;
	else if(pInfo[playerid][pNivel] == 18) pInfo[playerid][pExp] = 500;
	else if(pInfo[playerid][pNivel] == 17) pInfo[playerid][pExp] = 450;
	else if(pInfo[playerid][pNivel] == 16) pInfo[playerid][pExp] = 400;
	else if(pInfo[playerid][pNivel] == 15) pInfo[playerid][pExp] = 350;
	else if(pInfo[playerid][pNivel] == 14) pInfo[playerid][pExp] = 300;
	else if(pInfo[playerid][pNivel] == 13) pInfo[playerid][pExp] = 250;
	else if(pInfo[playerid][pNivel] == 12) pInfo[playerid][pExp] = 200;
	else if(pInfo[playerid][pNivel] == 11) pInfo[playerid][pExp] = 180;
	else if(pInfo[playerid][pNivel] == 10) pInfo[playerid][pExp] = 150;
	else if(pInfo[playerid][pNivel] == 9) pInfo[playerid][pExp] = 130;
	else if(pInfo[playerid][pNivel] == 8) pInfo[playerid][pExp] = 100;
	else if(pInfo[playerid][pNivel] == 7) pInfo[playerid][pExp] = 75;
	else if(pInfo[playerid][pNivel] == 6) pInfo[playerid][pExp] = 50;
	else if(pInfo[playerid][pNivel] == 5) pInfo[playerid][pExp] = 36;
	else if(pInfo[playerid][pNivel] == 4) pInfo[playerid][pExp] = 24;
	else if(pInfo[playerid][pNivel] == 3) pInfo[playerid][pExp] = 15;
	else if(pInfo[playerid][pNivel] == 2) pInfo[playerid][pExp] = 5;
	else if(pInfo[playerid][pNivel] == 1) pInfo[playerid][pExp] = 0;
	return pInfo[playerid][pExp];
}

stock GetRespetoMinimo(level) //Cuenta cuánto falta para el siguiente nivel
{
	new RespetoMinimo;
	if(level == 0 || level == 1) RespetoMinimo = 0;
	else if(level == 2) RespetoMinimo = 5;
	else if(level == 3) RespetoMinimo = 15;
	else if(level == 4) RespetoMinimo = 24;
	else if(level == 5) RespetoMinimo = 36;
	else if(level == 6) RespetoMinimo = 50;
	else if(level == 7) RespetoMinimo = 75;
	else if(level == 8) RespetoMinimo = 100;
	else if(level == 9) RespetoMinimo = 130;
	else if(level == 10) RespetoMinimo = 150;
	else if(level == 11) RespetoMinimo = 180;
	else if(level == 12) RespetoMinimo = 200;
	else if(level == 13) RespetoMinimo = 250;
	else if(level == 14) RespetoMinimo = 300;
	else if(level == 15) RespetoMinimo = 350;
	else if(level == 16) RespetoMinimo = 400;
	else if(level == 17) RespetoMinimo = 450;
	else if(level == 18) RespetoMinimo = 500;
	else if(level == 19) RespetoMinimo = 550;
	else if(level >= 20) RespetoMinimo = 1000;
	return RespetoMinimo;
}



stock NombreJugador(playerid)
{

    new NombrePJ[24];
    GetPlayerName(playerid,NombrePJ,24);
    new N[24];
    strmid(N,NombrePJ,0,strlen(NombrePJ),24);
    for(new i = 0; i < MAX_PLAYER_NAME; i++){
        if (N[i] == '_') N[i] = ' ';
    }
    return N;

}

stock ProxDetector(Float:radi, playerid, string[],col1,col2,col3,col4,col5)
{
	new Float:posx, Float:posy, Float:posz;
	GetPlayerPos(playerid, posx, posy, posz);
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i) && (GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i)))
		{
			if(BigEar[i] == 0)
			{
			    if(IsPlayerInRangeOfPoint(i, radi / 16, posx, posy, posz)) {
					SendClientMessage(i, col1, string);
				}
				else if(IsPlayerInRangeOfPoint(i, radi / 8, posx, posy, posz)) {
					SendClientMessage(i, col2, string);
				}
				else if(IsPlayerInRangeOfPoint(i, radi / 4, posx, posy, posz)) {
					SendClientMessage(i, col3, string);
				}
				else if(IsPlayerInRangeOfPoint(i, radi / 2, posx, posy, posz)) {
					SendClientMessage(i, col4, string);
				}
				else if(IsPlayerInRangeOfPoint(i, radi, posx, posy, posz)) {
					SendClientMessage(i, col5, string);
				}
			}
			else
			{
				SendClientMessage(i, col1, string);
			}
		}
	}
	return 1;
}

stock ProxDetectorEx(Float:radi, playerid, string[], color)
{
	new Float:posx, Float:posy, Float:posz;
	GetPlayerPos(playerid, posx, posy, posz);
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i) && (GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i)))
		{
			if(BigEar[i] == 0)
			{
   				if(IsPlayerInRangeOfPoint(i, radi, posx, posy, posz)) {
   					SendClientMessage(i, color, string);
     			}
			}
			else {
				SendClientMessage(i, color, string);
			}
		}
	}
	return 1;
}

 ProxDetectorS(Float:radi, playerid, targetid)
{
    if(IsPlayerConnected(playerid)&&IsPlayerConnected(targetid))
	{
		new Float:posx, Float:posy, Float:posz;
		GetPlayerPos(playerid, posx, posy, posz);
		if(IsPlayerInRangeOfPoint(targetid, radi, posx, posy, posz))
		{
			return 1;
		}
	}
	return 0;
}

ProxDetectorBcmd(Float:radi, playerid, string[],col1,col2,col3,col4,col5)
{
	new Float:posx, Float:posy, Float:posz;
	GetPlayerPos(playerid, posx, posy, posz);
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i) && (GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i)))
		{
		    if(gBcmd[i] == 0)
		    {
				if(BigEar[i] == 0)
				{
				    if(IsPlayerInRangeOfPoint(i, radi / 16, posx, posy, posz)) {
						SendClientMessage(i, col1, string);
					}
					else if(IsPlayerInRangeOfPoint(i, radi / 8, posx, posy, posz)) {
						SendClientMessage(i, col2, string);
					}
					else if(IsPlayerInRangeOfPoint(i, radi / 4, posx, posy, posz)) {
						SendClientMessage(i, col3, string);
					}
					else if(IsPlayerInRangeOfPoint(i, radi / 2, posx, posy, posz)) {
						SendClientMessage(i, col4, string);
					}
					else if(IsPlayerInRangeOfPoint(i, radi, posx, posy, posz)) {
						SendClientMessage(i, col5, string);
					}
				}
				else
				{
					SendClientMessage(i, col1, string);
				}
			}
		}
	}
	return 1;
}

stock ABroadCast(color,string[],level)
{
foreach(Player, i)
{
	if (pInfo[i][pAdmin] >= level && AdminChat[i] == 0)
	{
		SendClientMessage(i, color, string);
	}
}
return 1;
}

stock AdminOnDuty(const playerid)
{
	if(pInfo[playerid][pAdminDuty] == 1) return 1;
	return 0;
}

stock SetAdminColor(playerid)
{
    switch(pInfo[playerid][pAdmin]) {
        	case 1:
        	{
        	    SetPlayerColor(playerid, CELESTE_ADMIN);
        	}
        	case 2:
        	{
        	    SetPlayerColor(playerid, ORANGE_ADMIN);
        	}
        	case 3:
        	{
        	    SetPlayerColor(playerid, VERDE_ADMIN);
        	}
        	case 4:
        	{
        	    SetPlayerColor(playerid, AMARILLO_ADMIN);
        	}
        	case 5:
        	{
        	    SetPlayerColor(playerid, PURPURA_ADMIN);
        	}
        	case 6:
        	{
        	    SetPlayerColor(playerid, CREMA_ADMIN);
        	}
        	case 7:
        	{
        	    SetPlayerColor(playerid, COL_CRIMSON);
        	}
        }
}


stock SetPosEx(playerid, Float:X, Float:Y, Float:Z, Float:A, interiorid, worldid)
{
SetPlayerPos(playerid, X, Y, Z);
SetPlayerFacingAngle(playerid, A);
SetPlayerInterior(playerid, interiorid);
SetPlayerVirtualWorld(playerid, worldid);
pInfo[playerid][Interior] = worldid;
}


stock PreloadAnimLib(playerid, animlib[]) ApplyAnimation(playerid,animlib,"null",0.0,0,0,0,0,0);



forward MostrarDNI(playerid,targetid);
public MostrarDNI(playerid,targetid)
{
    if(IsPlayerConnected(playerid)&&IsPlayerConnected(targetid))
	{
	    new string[50], sex[20];
	    if(pInfo[playerid][pSexo] == 1) { sex = "Masculino"; }
   		else								{ sex = "Femenino"; }
   		//new raza[24], sql[70];
		//format(sql, sizeof(sql), "SELECT pRaza FROM `jugadores` WHERE `ID` = %i", pInfo[playerid][ID]);
		//mysql_query(g_SQL, sql);
	    //cache_get_value_name(0, "pRaza", raza);
	    //format(pInfo[playerid][pRaza], sizeof(raza), "%s", raza);
	    SendClientMessage(targetid, COL_VERDEOSCURO, "|___________ Documento Nacional de Identidad de Los Santos ___________|");
   		format(string, sizeof(string), "   Nombre: %s", NombreJugador(playerid));
   		SendClientMessage(targetid, COL_AMARILLOVIEJO, string);
   		format(string, sizeof(string), "   Sexo: %s",  sex);
   		SendClientMessage(targetid, COL_AMARILLOVIEJO, string);
   		format(string, sizeof(string), "   Edad: %d", pInfo[playerid][pEdad]);
   		SendClientMessage(targetid, COL_AMARILLOVIEJO, string);
   		/*if(PlayerInfo[playerid][pMarried] == 1) format(string, sizeof(string), "   Estado Civil: Casado			Con: %s", PlayerInfo[playerid][pMarriedTo]);
		else format(string, sizeof(string), "   Estado Civil: Soltero");*/
   		//Message(targetid, COLOR_WHITE, string);
   		format(string, sizeof(string), "   Nº DNI: %i", pInfo[playerid][pDNI]);
   		SendClientMessage(targetid, COL_AMARILLOVIEJO, string);
   		SendClientMessage(targetid, COL_VERDEOSCURO, "|_____________________________________________________________________|");
	}
	return 1;
}




//====================================================================================================================================================================================//

//                                                                          C  O  M  A  N  D  O  S

//====================================================================================================================================================================================//
//------------- CHAT

CMD:me(playerid, params[])
{
    new string[128], action[100];
    if(sscanf(params, "s[100]", action))
    {
        SendClientMessage(playerid, -1, "Uso: /me <acción>");
        return 1;
    }
    else
    {
        format(string, sizeof(string), "* %s %s", NombreJugador(playerid), action);
        ProxDetectorEx(30, playerid, string, COL_PURPURA);
    }
    return 1;
}

CMD:do(playerid, params[])
	{

        if(!sscanf(params, "s[128]", params[0]))
        {
            new string[128];
			format(string, sizeof(string), "* %s (( %s )).", NombreJugador(playerid), params[0]);
            ProxDetectorEx(30.0, playerid, string, 0xB6DB22FF);
        } else SendClientMessage(playerid, -1, "Uso: /do <acción>");
        return 1;
    }

CMD:s(playerid, params[])
	{

        if(!sscanf(params, "s[128]", params[0]))
        {
            new string[128];
            format(string, sizeof(string), "%s susurra: %s", NombreJugador(playerid), params[0]);
            ProxDetector(3.0, playerid, string,COLOR_FADE1,COLOR_FADE2,COLOR_FADE3,COLOR_FADE4,COLOR_FADE5);
        } else SendClientMessage(playerid, -1, "Uso: /s <texto>");
        return 1;
    }

CMD:g(playerid, params[])
{

    new string[128], shout[100];
    if(sscanf(params, "s[100]", shout))
    {
        SendClientMessage(playerid, -1, "Uso: /(g)ritar [mensaje]");
        return 1;
    }
    else
    {
        format(string, sizeof(string), "%s grita: ¡¡ %s !!", NombreJugador(playerid),shout);
        ProxDetectorEx(50.0, playerid, string, -1);
    }
    return 1;
}

CMD:b(playerid, params[])
    {

        if(!sscanf(params, "s[128]", params[0]))
        {
            new string[128];
            format(string, sizeof(string), "(( %s (%d) dice: %s ))", NombreJugador(playerid), playerid, params[0]);
			ProxDetectorBcmd(15.0, playerid, string,COLOR_FADE1,COLOR_FADE2,COLOR_FADE3,COLOR_FADE4,COLOR_FADE5);
        } else SendClientMessage(playerid, -1, "Uso: /b <Canal OOC>");
        return 1;
    }






//------------- Administrativo

CMD:j(playerid, params[])
{

	new string[128], text[100];
	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if (pInfo[playerid][pAdmin] < 1) return NoAutorizado
	if(sscanf(params, "s[100]", text)) return SendClientMessage(playerid, -1, "Uso: /j [Texto OOC ADMIN]");
 	format(string, sizeof(string), "Admin %s %s dice: %s", pInfo[playerid][pAdminLvl], NombreJugador(playerid) , text);
	ProxDetectorEx(60.0, playerid, string, GetPlayerColor(playerid));
	return 1;
}

CMD:setadmin(playerid, params[])
{
		new string[128], name[32];
   	    /*if(pInfo[playerid][pAdmin] != 7) return SendClientMessage(playerid, COL_CRIMSON, "No estás autorizado a usar este comando!");*/
   	    if(!sscanf(params, "s[32]i", name, params[1]))
		   {
		new str[128];
		format(str, sizeof(str), "SELECT * FROM `jugadores` WHERE `username` = '%s'", pInfo[playerid][Name]);
		mysql_query(g_SQL, str);
		if(cache_num_rows() > 0)
		{
				new query[1024];
				mysql_format(g_SQL, query, sizeof query, "UPDATE `jugadores` SET `pAdmin` = %i WHERE `id` = %d",
				params[1], pInfo[playerid][ID]);
				mysql_tquery(g_SQL, query);
				format(string, sizeof(string), "{408080}%s puso en %d el nivel admin de %s",NombreJugador(playerid), params[1], name);
				ABroadCast(-1, string, 1);
				}

		else SendClientMessage(playerid, -1, "¡Esa cuenta no existe!");
		} else SendClientMessage(playerid, -1, "Uso: /setadmin <Nombre_Jugador> <Nivel>");
    	return 1;
   	}



CMD:aduty(playerid, params[])
{
    new status[4];
    new string[128];
    if(pInfo[playerid][pAdmin] == 0) return SendClientMessage(playerid, COL_CRIMSON,"* No estás autorizado a usar este comando!");
    if(sscanf(params,"s[4]",status))return SendClientMessage(playerid, -1, "Uso: /a[dmin]duty [On/Off]");
    if(strcmp(status, "on", true) == 0) {
        if(pInfo[playerid][pAdminDuty] == 0) {
            pInfo[playerid][pAdminDuty] = 1;
			SetAdminColor(playerid);
            format(string, sizeof(string),"Admin %s %s se encuentra en servicio", pInfo[playerid][pAdminLvl], NombreJugador(playerid));
            SendClientMessageToAll(COL_VERDEAQUA, string);

        }
        else return SendClientMessage(playerid, -1, "No estás off.");
    }
    if(strcmp(status, "off", true) == 0) {
        if(pInfo[playerid][pAdminDuty] == 1) {
            pInfo[playerid][pAdminDuty] = 0;
            SetPlayerColor(playerid, -1);
            format(string, sizeof(string),"Admin %s %s se encuentra fuera de servicio", pInfo[playerid][pAdminLvl], NombreJugador(playerid));
            SendClientMessageToAll(COL_VERDEAQUA, string);
            return SendClientMessage(playerid, -1, "Dejas de estar duty.");
        }
        else return SendClientMessage(playerid, -1, "No estás on.");
    }

    return 1;
}

CMD:darvida(playerid, params[])
{
	new str[128];
    if(pInfo[playerid][pAdmin] < 0) return SendClientMessage(playerid, COL_CRIMSON,"* No estás autorizado a usar este comando!");
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if(sscanf(params, "ui", params[0], params[1])) return SendClientMessage(playerid, -1, "Uso: /sethp <id> <HP>");
	if(!IsPlayerConnected(params[0])) return SendClientMessage(playerid,  COL_GRIS, "* ID Inválida");
	if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
	SetPlayerHealth(params[0],params[1]);
	format(str, sizeof(str), "{CC2538}AdminCmd:{FFFFFF} %s estableció la salud de %s a %dHP.", NombreJugador(playerid),NombreJugador(params[0]),params[1]);
	ABroadCast(-1, str, 3);
	return 1;
}

CMD:darchaleco(playerid, params[])
{
    new str[128];
    if(pInfo[playerid][pAdmin] < 2) return SendClientMessage(playerid, COL_CRIMSON,"* No estás autorizado a usar este comando!");
	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if(sscanf(params, "ui", params[0], params[1])) return SendClientMessage(playerid, -1, "Uso: /setarmor <id> <Chaleco>");
	if(!IsPlayerConnected(params[0])) return SendClientMessage(playerid,  COL_GRIS, "* ID Inválida");
	if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
	SetPlayerArmour(params[0],params[1]);
	format(str, sizeof(str), "{CC2538}AdmCmd:{FFFFFF} %s estableció el chaleco de %s a %d.", NombreJugador(playerid),NombreJugador(params[0]),params[1]);
	ABroadCast(-1, str, 3);
    return 1;
}

CMD:kick(playerid, params[])
{
    if(pInfo[playerid][pAdmin] == 0) return SendClientMessage(playerid, COL_CRIMSON,"* No estás autorizado a usar este comando!");
	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
	if (pInfo[playerid][pAdmin] >= 1)
	{
	    new string[128], giveplayerid, reason[64];
  		if(sscanf(params, "ds[64]", giveplayerid, reason)) return SendClientMessage(playerid, -1, "Uso: /kick <id> <razón>");
		if(IsPlayerConnected(giveplayerid))
		{
			if(pInfo[giveplayerid][pAdmin] > pInfo[playerid][pAdmin])
			{
				format(string, sizeof(string), "{CC2538}AdmCmd:{FFFFFF} %s ha sido auto-expulsado, razón: Intentar usar /kick a un administrador mayor.", NombreJugador(playerid));
				ABroadCast(-1,string,1);
	        	SendClientMessage(playerid, -1,"{CC2538}ATENCIÓN:{FFFFFF}  Fuiste baneado por seguridad, por intentar expulsar a un administrador de mayor rango.");
	        	Kick(playerid);
				return 1;
			}
			else
			{
				new year, month,day;
				getdate(year, month, day);
				new playerip[32];
				GetPlayerIp(giveplayerid, playerip, sizeof(playerip));
				format(string, sizeof(string), "{CC2538}AdmCmd:{FFFFFF} (IP:%s) fue expulsado por %s, razón: %s (%d-%d-%d)", NombreJugador(giveplayerid), playerip, NombreJugador(playerid), reason,month,day,year);
				new query[600];
				mysql_format(g_SQL, query, sizeof query, "INSERT INTO `log administrativo` (`groupID`, `log`) VALUES ('1', '(IP:%s) %s fue expulsado por %s, razón: %s (%d-%d-%d)')", playerip, NombreJugador(giveplayerid), NombreJugador(playerid), reason,month,day,year);
	            mysql_tquery(g_SQL, query);
    			format(string, sizeof(string), "{CC2538}AdmCmd:{FFFFFF} %s fue expulsado por %s, razón: %s", NombreJugador(giveplayerid), NombreJugador(playerid), reason);
				ABroadCast(-1,string,1);
				format(string, 128, "{CC2538}ATENCIÓN:{FFFFFF} fuiste kickeado por %s, razón: %s", NombreJugador(playerid), reason);
    			SendClientMessage(giveplayerid, -1, string);
				DelayedKick(playerid);

			}
			return 1;
		}
		else SendClientMessage(playerid, COL_GRIS, "Esa ID es inválida.");
	}
	else NoAutorizado
	return 1;
}

CMD:a(playerid, params[])
    {
        if(pInfo[playerid][pAdmin] == 0) return SendClientMessage(playerid, COL_CRIMSON,"* No estás autorizado a usar este comando!");
		if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
        if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
        if(!sscanf(params, "s[128]", params[0])){
            new string[128];
            format(string, sizeof(string), "Admin %s %s: %s", pInfo[playerid][pAdminLvl], NombreJugador(playerid), params[0]);
            if(pInfo[playerid][pAdmin] > 0 && pInfo[playerid][pAdmin] < 5) ABroadCast(0x266FB7FF, string,1);
			else if(pInfo[playerid][pAdmin] >= 5 && pInfo[playerid][pAdmin] < 8) ABroadCast(0xC91414FF, string,1);
			else SendClientMessage(playerid, -1, "{FFFFFF}* No admin {3F96CB}rank{FFFFFF}! (???)");
        } else SendClientMessage(playerid, -1, "Uso: /a <Texto>");
        return 1;
    }

CMD:ls(playerid, params[])
{

	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if(pInfo[playerid][pAdmin] >= 1){
    	if (GetPlayerState(playerid) == 2)
		{
			return SetVehiclePos(GetPlayerVehicleID(playerid), 1529.6,-1691.2,13.3);
		}
		else{
			SetPosEx(playerid, 1529.6,-1691.2,13.3, 0, 0 ,0);
		}
	}
	else NoAutorizado
	return 1;
}

CMD:sf(playerid, params[])
{

	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if (pInfo[playerid][pAdmin] < 1) return NoAutorizado
    if (GetPlayerState(playerid) == 2){
		return SetVehiclePos(GetPlayerVehicleID(playerid), -1417.0,-295.8,14.1);
	}
	else{
		SetPosEx(playerid, -1417.0,-295.8,14.1, 0, 0 ,0);
		return 1;
	}
}

CMD:lv(playerid, params[])
{

	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if (pInfo[playerid][pAdmin] < 1) return NoAutorizado
    if (GetPlayerState(playerid) == 2){
		return SetVehiclePos(GetPlayerVehicleID(playerid), 1694.6566,1453.4523,10.7632);
	}
	else{
		SetPosEx(playerid, 1694.6566,1453.4523,10.7632, 0, 0 ,0);
		return 1;
	}
}

CMD:congelar(playerid,params[])
{
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if (pInfo[playerid][pAdmin] < 1) return NoAutorizado
    if(pInfo[playerid][pAdmin] >= 1)
    {
	        new Target; //defines the playerid we wanna freeze
	        if(sscanf(params, "u", Target)) SendClientMessage(playerid, -1, "{B43535}Uso:{FFFFFF}  /congelar [ID]"); //tell sscanf again if the parameters/syntax is wrong to return a special message
	        if(!IsPlayerConnected(Target)) //if the ID doesn't exist, return an error-message
                return SendClientMessage(playerid, COL_GRIS, "ERROR: Jugador no conectado.");
	        if(!sscanf(params, "u", Target))
		    {

   			   if(pInfo[Target][pAdmin] > pInfo[playerid][pAdmin]) return SendClientMessage(playerid, COL_CRIMSON,"ERROR: No podés congelar admins de mayor nivel"); // if the player you're performing this command on has a higher level as you, return a message, you ain't able to freeze him
           	   new tname[MAX_PLAYER_NAME]; //define the new target-name of the playerid
			   GetPlayerName(Target,tname,sizeof(tname)); //get the playername with this function
			   new pname[MAX_PLAYER_NAME]; //define the adminname
			   GetPlayerName(playerid,pname,sizeof(pname)); //get the adminname with this function
			   new tstring[128]; //define the string for the player (victim)
			   new pstring[128];// define the string for the admin which is performing
			   format(tstring,sizeof(tstring),"Has sido congelado por %s! No te podés mover más!",pname); //this is formatting the player-string, while it's also getting the adminname
			   format(pstring,sizeof(pstring),"Has congelado a %s(%d)!",tname,Target); //this is formatting the adminname-string, while it's also getting the playername and his ID(target)
			   //this is formatting the all-string, while it's sending this message to everybody and is getting admin- and playername
			   SendClientMessage(Target,ORANGE_ADMIN,tstring);//sends the message to the victim
			   SendClientMessage(playerid,ORANGE_ADMIN,pstring);//sends the message to the admin
			   //sends the message to everybody
			   TogglePlayerControllable(Target,0); //with that function, the player won't be able to mov, while we're using the variable "Target" as the playerid
			   pInfo[Target][pFrozen] = 1;//IMPORTANT:we're getting the variable "[frozen]" out of the enum, and set it's value to "1', the compiler knows now that the player is frozen
            }

	}

// if he doesn't have permissions, return that message!
	return 1;
}

CMD:descongelar(playerid,params[])
{
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if (pInfo[playerid][pAdmin] < 1) return NoAutorizado
    if(pInfo[playerid][pAdmin] >= 1)
    {
	        new Target; //defines the playerid we wanna unfreeze
	        if(sscanf(params, "u", Target)) SendClientMessage(playerid, -1, "Uso:  /descongelar [ID]"); //tell sscanf again if the parameters/syntax is wrong to return a special message
	        if(!IsPlayerConnected(Target)) //if the ID doesn't exist, return an error-message
                return SendClientMessage(playerid, COL_GRIS, "ERROR: Jugador no conectado.");
	        if(!sscanf(params, "u", Target))
		    {

         		if(pInfo[Target][pAdmin] > pInfo[playerid][pAdmin]) return SendClientMessage(playerid, COL_CRIMSON,"ERROR: No podés descongelar admins de mayor nivel"); // if the player you're performing this command on has a higher level as you, return a message, you ain't able to unfreeze him
                new tname[MAX_PLAYER_NAME]; //define the new target-name of the playerid
				GetPlayerName(Target,tname,sizeof(tname)); //get the playername with this function
				new pname[MAX_PLAYER_NAME]; //define the adminname
				GetPlayerName(playerid,pname,sizeof(pname)); //get the adminname with this function
				new tstring[128]; //define the string for the player (victim)
				new pstring[128];// define the string for the admin which is performing
				format(tstring,sizeof(tstring),"Has sido descongelad %s! Ahora te podés mover.",pname); //this is formatting the player-string, while it's also getting the adminname
				format(pstring,sizeof(pstring),"Has descongelado a %s(%d)!",tname,Target); //this is formatting the adminname-string, while it's also getting the playername and his ID(target)
				SendClientMessage(Target,ORANGE_ADMIN,tstring);//sends the message to the victim
			    SendClientMessage(playerid,ORANGE_ADMIN,pstring);//sends the message to the admin
				TogglePlayerControllable(Target,1); //with that function, the player will be able to move again, while we're using the variable "Target" as playerid again
				pInfo[Target][pFrozen] = 0;//IMPORTANT:we're getting the variable "[frozen]" out of the enum, and set it's value to "0", the compiler knows now that the player is unfrozen
            }

	}
    return 1;
}

COMMAND:limpiarchat(playerid,params[])
{
	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
	if (pInfo[playerid][pAdmin] < 1) return NoAutorizado
    if(pInfo[playerid][pAdmin] >= 2)
	{
	for( new i = 0; i <= 100; i ++ ) SendClientMessageToAll( -1, "" );
	}	return 1;
}


CMD:enviarls(playerid, params[])
{
	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
	if (pInfo[playerid][pAdmin] >= 1)
	{
		new string[128], giveplayerid;
		if(sscanf(params, "d", giveplayerid)) return SendClientMessage(playerid, -1, "Uso: /enviarls [ID]");
		if(IsPlayerConnected(giveplayerid))
		{
			if (pInfo[giveplayerid][pAdmin] > pInfo[playerid][pAdmin]) return SendClientMessage(playerid, COL_CRIMSON, "No puedes usar este comando para este jugador!");
			format(string, sizeof(string), " Enviaste este jugador a Los Santos.");
			SendClientMessage(playerid, -1, string);
			SendClientMessage(giveplayerid, ORANGE_ADMIN, "Fuiste teleportado!");
			SetPlayerPos(giveplayerid, 1529.6,-1691.2,13.3);
			SetPlayerVirtualWorld(giveplayerid, 0);
			SetPlayerInterior(giveplayerid, 0);
			pInfo[giveplayerid][Interior] = 0;
			pInfo[giveplayerid][pVirtualWorld] = 0;
		}
	}
	else NoAutorizado
	return 1;
}

CMD:ir(playerid,params[])
{
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
	if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, -1, "{B43535}Uso:{FFFFFF} /ir <ID>");
	if(IsPlayerConnected(params[0]))
	{
	   	new Float:p_x,Float:p_y,Float:p_z;
	   	GetPlayerPos(params[0], p_x,p_y,p_z);
	   	new interior = GetPlayerInterior(params[0]);
	   	new vw = GetPlayerVirtualWorld(params[0]);
    	SetPosEx(playerid, p_x,p_y,p_z,0,interior,vw);
    	return SendClientMessage(playerid, ORANGE_ADMIN, "Teleportado!");
 	}
	else SendClientMessage(playerid, COL_GRIS, "* Esa ID es inválida.");
    return 1;
}

CMD:traer(playerid,params[])
{
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
    if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
    new giveplayerid;
    if(sscanf(params, "u", giveplayerid)) return SendClientMessage(playerid, -1, "{B43535}Uso:{FFFFFF} /traer <ID>");
	if(IsPlayerConnected(giveplayerid))
	{
	    if(pInfo[giveplayerid][pAdmin] == 6) return SendClientMessage(playerid, COL_GRIS, "* No puedes traer a un jugador de alto rango administrativo.");
	    new Float:p_x,Float:p_y,Float:p_z;
	    GetPlayerPos(playerid, p_x,p_y,p_z);
	    new interior = GetPlayerInterior(playerid);
	    new vw = GetPlayerVirtualWorld(playerid);
    	SetPosEx(giveplayerid, p_x,p_y,p_z,0,interior,vw);
    	return SendClientMessage(giveplayerid, ORANGE_ADMIN, "Teleportado!");
  	}
	else SendClientMessage(playerid, COL_GRIS, "Esa ID es inválida.");
    return 1;
}

CMD:spec(playerid, params[])
{
	if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
	if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
	if(pInfo[playerid][pAdmin] >= 1)
	{
	    new userID;
		if(sscanf(params, "u", userID)) return SendClientMessage(playerid, -1, "Uso: /spec [id]");
		else if(!IsPlayerConnected(userID)) return SendClientMessage(playerid, -1, "* El jugador especificado no está conectado.");
		else
		{
			pInfo[playerid][pSpectating] = userID;
		    TogglePlayerSpectating(playerid, true);
			SetPlayerInterior(playerid, GetPlayerInterior(userID));
			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(userID));
		    if(IsPlayerInAnyVehicle(userID)) { PlayerSpectateVehicle(playerid, GetPlayerVehicleID(userID)); }
		    else { PlayerSpectatePlayer(playerid, userID); }

		}
	}
	else NoAutorizado
	return 0;
}

CMD:specoff(playerid, params[])
{
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);
	if(pInfo[playerid][pAdmin] < 1) return NoAutorizado
	if(pInfo[playerid][pSpectating] != -1)
	{
		pInfo[playerid][pSpectating] = -1;
		TogglePlayerSpectating(playerid, false);
		SetCameraBehindPlayer(playerid);
		SetPlayerPos(playerid, pInfo[playerid][X_Pos], pInfo[playerid][Y_Pos], pInfo[playerid][Z_Pos]);
		SetPlayerInterior(playerid, pInfo[playerid][Interior]);
		SetPlayerVirtualWorld(playerid, pInfo[playerid][pVirtualWorld]);
		return 1;
	}
	else SendClientMessage(playerid, -1, "No estás spectando a nadie.");
	return 0;
}

CMD:guardarcuenta(playerid, params[])
{
    UpdatePlayerData(playerid);
    return 1;
}

CMD:dararma(playerid, params[])
{
        /*if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 1) return SendClientMessage(playerid, -1, NODUTY);*/
		/*if(pInfo[playerid][pAdmin] <= 0) return NoAutorizado*/
		new target, gun, string[128];
        if(sscanf(params, "ud", target, gun, params[0])) {
			SendClientMessage(playerid, -1, "Uso:{FFFFFF} /dararma <ID> <IDArma> <Municiones>");
		    SendClientMessage(playerid, COL_VERDEPASTEL, "_______________________________________");
		    SendClientMessage(playerid, COL_CELESTEPASTEL, "1: Brass Knuckles 2: Golf Club 3: Nite Stick 4: Knife 5: Baseball Bat 6: Shovel 7: Pool Cue 8: Katana 9: Chainsaw");
	        SendClientMessage(playerid, COL_CELESTEPASTEL, "10: Purple Dildo 11: Small White Vibrator 12: Large White Vibrator 13: Silver Vibrator 14: Flores 15: Cane 16: Frag Grenade");
		    SendClientMessage(playerid, COL_CELESTEPASTEL, "17: Tear Gas 18: Molotov Cocktail 19: Vehicle Missile 20: Hydra Flare 21: Jetpack 22: 9mm 23: Silenced 9mm 24: Desert Eagle");
		    SendClientMessage(playerid, COL_CELESTEPASTEL, "26: Sawnoff Shotgun 27: Combat Shotgun 28: Micro SMG (Mac 10) 29: SMG (MP5) 30: AK-47 31: M4 32: Tec9 33: Rifle");
		    SendClientMessage(playerid, COL_CELESTEPASTEL, "25: Shotgun 34: Sniper Rifle 35: Rocket Launcher 36: HS Rocket Launcher 37: Flamethrower 38: Minigun 39: Satchel Charge");
		    SendClientMessage(playerid, COL_CELESTEPASTEL, "40: Detonator 41: Spraycan 42: Fire Extinguisher 43: Camera 46: Parachute");
		    SendClientMessage(playerid, COL_VERDEPASTEL, "_______________________________________");
	    	return 1;
	    }
        if(gun < 1 || gun > 47) return SendClientMessage(playerid, COL_GRIS, "Armas de 1-46.");
        if (params[0] < 1 || params[0] > 999) return SendClientMessage(playerid, COL_GRIS, "Municiones de 1 a 999.");
        if(!IsPlayerConnected(target)) return SendClientMessage(playerid, COL_GRIS, "Usuario no conectado!");
        if(gun != 21)
        {
            GivePlayerWeapon(target, gun, params[0]); //Your version would be GivePlayerValidWeapon, this also may be causing issues.
            format(szMessage, sizeof(szMessage), "{B43535}AdmCmdExe:{FFFFFF} %s ha dado un arma [ID Arma: %d] a %s.", NombreJugador(playerid), gun, NombreJugador(target));
			ABroadCast(-1, szMessage, 5);
			format(string, sizeof(string), "Admin %s te dió un arma.", NombreJugador(playerid));
            SendClientMessage(target, -1, string);
            format(string, sizeof(string), "Le diste a %s un arma.", NombreJugador(target));
            SendClientMessage(playerid, -1, string);
        }
        return 1;
}

CMD:crearfacc(playerid, params[])
{
        if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 6) return SendClientMessage(playerid, -1, NODUTY);
		if(pInfo[playerid][pAdmin] <= 0) return NoAutorizado
		new str[87+1];
		format(str, sizeof(str), "%s{FFFFFF}Bienvenido al creador de facciones\n\n Ingresá el nombre de la facción a crear:", str);
		ShowPlayerDialog(playerid, DIALOG_FNOMBRE, DIALOG_STYLE_INPUT, "{CC2538}CREAR FACCION:{FFFFFF} NOMBRE", str, "Aceptar", "Cancelar");
        return 1;
}

CMD:hacerlider(playerid, params[])
{
		new string[128];		
        if(pInfo[playerid][pAdmin] < 6 && pInfo[playerid][pFaccion] == 0) 	return NoAutorizado
		if(sscanf(params, "ui", params[0], params[1])) 		return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /hacerlider [ID] [ID Facción]");
  		if(params[1] == 0) 		return SendClientMessage(playerid, COLOR_FADE, "ID facción incorrecto.");
    	if(!IsPlayerConnected(params[0])) {
    		SendClientMessage(playerid, COLOR_FADE, "Jugador desconectado.");
    	}
    	if (pInfo[params[0]][pFaccion] == params[1]) {
    		SendClientMessage(playerid, COLOR_FADE, "El jugador ya es líder de la facción.");
    	}
    	else {
    		if (pInfo[params[0]][pFaccion] >= 1) {
				pInfo[playerid][pFaccion] = params[1];
				pInfo[playerid][pRango] = 7;
				new faccid = params[1];	
				fInfo[faccid][fID] = faccid;			
				format(fInfo[faccid][fLider], 64, "%s", NombreJugador(params[0]));				
				format(szMessage, sizeof(szMessage), "{CC2538}AdmCmdExe:{FFFFFF} %s hizo lider de facción a %s.", NombreJugador(playerid), NombreJugador(params[0]));
				ABroadCast(-1, szMessage, 5);
				format(string, sizeof(string), "El admin %s te hizo lider de la facción.", NombreJugador(playerid));
	            SendClientMessage(params[0], -1, string);
	            format(string, sizeof(string), "Hiciste líder a %s.", NombreJugador(params[0]));
	            SendClientMessage(playerid, -1, string);
	            SaveFaccs(faccid);
            }

            else {
				SendClientMessage(playerid, COLOR_FADE, "El jugador ya tiene facción, despedilo (/despedirlider) antes de hacerlo lider.");            	
            }
    	}
        return 1;
}

CMD:despedirlider(playerid, params[])
{
	new string[128];
	if(pInfo[playerid][pAdmin] < 6 && pInfo[playerid][pFaccion] == 0) 	return NoAutorizado
	if(sscanf(params, "ui", params[0], params[1])) 		return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /despedirlider [ID] [ID Facción]");
	if(params[1] == 0) 		return SendClientMessage(playerid, COLOR_FADE, "ID facción incorrecto.");
    if(!IsPlayerConnected(params[0])) {SendClientMessage(playerid, COLOR_FADE, "Jugador desconectado.");}	
    else {
    	if (pInfo[params[0]][pFaccion] == params[1] || pInfo[params[0]][pRango] == 7) {
    		pInfo[playerid][pFaccion] = 0;
			pInfo[playerid][pRango] = 0;
			new faccid = params[1];	
			fInfo[faccid][fID] = faccid;			
			format(fInfo[faccid][fLider], 64, "Vacio");				
			format(szMessage, sizeof(szMessage), "{CC2538}AdmCmdExe:{FFFFFF} %s despidió de lider de facción a %s.", NombreJugador(playerid), NombreJugador(params[0]));
			ABroadCast(-1, szMessage, 5);
			format(string, sizeof(string), "El admin %s te despidió de lider de la facción.", NombreJugador(playerid));
            SendClientMessage(params[0], -1, string);
            format(string, sizeof(string), "Despediste de líder a %s.", NombreJugador(params[0]));
            SendClientMessage(playerid, -1, string);
            SaveFaccs(faccid);
    		}

    		else {
    			SendClientMessage(playerid, COLOR_FADE, "Este jugador no es líder.");
    		}
    }
    return 1;
}


CMD:listafacciones(playerid, params[])
{
    if(!AdminOnDuty(playerid) && pInfo[playerid][pAdmin] >= 6) return SendClientMessage(playerid, -1, NODUTY);
	SendClientMessage(playerid, ORANGE_ADMIN, "Facciones en la base de datos:");
    new sql[80], query[50], string[150];
	format(sql, sizeof(sql), "SELECT * FROM `facciones` WHERE `borradoLogico` = 0");
	mysql_query(g_SQL, sql);
	new rows;
	cache_get_row_count(rows);
	for(new i = 0, j = rows; i < j; i++){		
		cache_get_value_name(i, "fNombre", query);
		format(fInfo[i][fNombre], 60, "%s", query);
		cache_get_value_int(i, "fID", fInfo[i][fID]);
		format(string, sizeof(string), "ID %i: %s", fInfo[i][fID], fInfo[i][fNombre]);
        SendClientMessage(playerid, ORANGE_ADMIN, string);
	}
    return 1;
}
//------ Comandos generales

CMD:aceptarmuerte(playerid, params[])
{
	if(pInfo[playerid][isAlive] == false)
	{
	SetTimerEx("StockAceptarMuerteAnim", 58000, false, "i", playerid);
    SetTimerEx("StockAceptarMuerte", 60000, false, "i", playerid);
    SendClientMessage(playerid, ORANGE_ADMIN, "Spawn en 1 minuto");
  	}
  	else{
  	SendClientMessage(playerid, -1, "No existe");
  	}
  	return 1;
}

CMD:cuenta(playerid, params[])
{
	new faccion[120], rango[120];
	//Facción
	if(pInfo[playerid][pFaccion] == 0){
		format(faccion, 120, "Sin facción");
		format(rango, 120, "Sin rango", rango);	
	}
	if(pInfo[playerid][pFaccion] > 1)
	{
		format(faccion, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fNombre]);
	}
	if(pInfo[playerid][pFaccion] > 1) //Parte de una facción
		{
	        switch(pInfo[playerid][pRango])
		    {
	            case 1: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango1]);
	            case 2: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango2]);
	            case 3: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango3]);
	            case 4: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango4]);
	            case 5: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango5]);
	            case 6: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango6]);
	            case 7: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango7]);
	        }
		}
	new str[200], str2[200];
	SendClientMessage(playerid, -1, "{AF1F30}|____________________INFORMACIÓN DE CUENTA____________________|");
	format(str, sizeof(str), "{D6D5C9}    ID: %i   |   Nivel: %i   |   Experiencia: %i    |   Raza: %s", pInfo[playerid][ID], pInfo[playerid][pNivel], pInfo[playerid][pExp], Nacionalidad);
	SendClientMessage(playerid, -1, str);
	format(str2, sizeof(str2), "{D6D5C9}    Skin activo: %i   |   Facción: %s   |   Rango: %s", pInfo[playerid][pSkin], faccion, rango);
	SendClientMessage(playerid, -1, str2);
	SendClientMessage(playerid, -1, "{AF1F30}|________________________________________________________________|");
	return 1;
}

CMD:cuenta2(playerid, params[])
{
	new faccion[120], rango[120];
	//Facción
	if(pInfo[playerid][pFaccion] == 0){
		format(faccion, 120, "Sin facción");
		format(rango, 120, "Sin rango", rango);	
	}
	if(pInfo[playerid][pFaccion] > 1)
	{
		format(faccion, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fNombre]);
	}
	if(pInfo[playerid][pFaccion] > 1) //Parte de una facción
		{
	        switch(pInfo[playerid][pRango])
		    {
	            case 1: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango1]);
	            case 2: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango2]);
	            case 3: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango3]);
	            case 4: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango4]);
	            case 5: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango5]);
	            case 6: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango6]);
	            case 7: format(rango, 120, "%s", fInfo[pInfo[playerid][pFaccion]][fRango7]);
	        }
		}
	new str[500+1];
	format(str, sizeof(str), "{C6D8D3}Información general:\n{FFFFFF}- ID: {CC2538}%i\n{FFFFFF}- Nivel: {CC2538}%i\n{FFFFFF}- Experiencia: {CC2538}%i\n{FFFFF", pInfo[playerid][ID], pInfo[playerid][pNivel], pInfo[playerid][pExp]);
	format(str, sizeof(str), "%sF}- Skin: {CC2538}%i\n{FFFFFF}- Raza: {CC2538}%s\n{FFFFFF}- Facción: {CC2538}%s\n{FFFFFF}- Rango: {CC2538}%s{FFFFFF}", str, pInfo[playerid][pSkin], Nacionalidad, faccion, rango);
	ShowPlayerDialog(playerid, 591, DIALOG_STYLE_MSGBOX, "{CC2538}INFORMACIÓN DE CUENTA", str, "Cerrar", "");
	return 1;
}

CMD:dni (playerid, params[])
    {
        if(sscanf(params, "u", params[0])) return SendClientMessage(playerid, COLOR_GRAD2, "Utilize: /dni <PlayerID>");
        if(!IsPlayerConnected(params[0])) return SendClientMessage(playerid, COLOR_GRAD2, "Jugador muy lejos.");
        if(ProxDetectorS(8.0, playerid, params[0]))
        {
	        new string[90];
	        MostrarDNI(playerid, params[0]);
	        new target = params[0];
	        format(string, sizeof(string), "* %s le muestra su DNI a %s.", NombreJugador(playerid), NombreJugador(target));
			ProxDetectorEx(30.0, playerid, string, COL_PURPURA);
		} else SendClientMessage(playerid, COLOR_FADE, "Jugador muy lejos.");
		return 1;
    }

