#include "mobilite.h"

//met � jour la position du noeud r�elle
void update_pos_noeud_BDD(noeud *node, MYSQL *mysql){
	char requete[256];

	sprintf(requete, "update noeuds set posX= %d, posY=%d where Id=%d", node->posX, node->posY, node->num_noeud);

	mysql_query(mysql, requete);
};

//met � jour les tables de routage lors des rencontres
void maj_tab_routage (noeud *node,  int portee, MYSQL *mysql, int nb_noeud){
	MYSQL_ROW row;
	MYSQL_RES *result;

	char requete[256];
	char Id_noeud[10];

	//requete pour s�lectionner les voisins d'un noeud
	sprintf(requete, "select Id from noeuds where ((((posX-%d)*(posX-%d))+((posY-%d)*(posY-%d))) <= %d) and Id <= %d", node->posX, node->posX, node->posY, node->posY, (int) pow(portee, 2), nb_noeud);

	if (mysql_query(mysql,requete)){
		printf("impossible de s�lectionner les voisins\n");
		exit(1);
	};
	// requ�te bonne, traitons les donn�es qu'elle renvoit
	result = mysql_store_result(mysql);
	while ((row = mysql_fetch_row(result))){
		unsigned long *lengths;
		lengths = mysql_fetch_lengths(result);
		//on r�cup�re l'Id
		sprintf(Id_noeud, "%.*s", (int) lengths[0], row[0] ? row[0] : "NULL");
		//printf("le noeud voisin a l'id: %s\n", Id_noeud);
		//tous les noeuds voisins de noeud vont avoir le m�me emplacement que celui de noeud
		sprintf(requete, "update routage set posX = %d, posY = %d, age = '0', posX_pdl = %d, posY_pdl = %d, age_pdl = '0' where Id = %d and Id_noeud = %s", node->posX, node->posY, node->posX, node->posY, node->num_noeud, Id_noeud);
		mysql_query(mysql,requete);
	};
	mysql_free_result(result);

};

void deplacer_noeud(noeud *node, int proba_mobilite, int taille, int waypoint){
	int bouge; //si bouge > proba_mobilite il ne bouge pas
	int dist, direction; //dist repr�sente la distance max que va parcourir le noeud pdt cette it�ration

	bouge = gener_alea(100); // on g�n�re un nb al�atoire entre 0 et 99
	dist = 1; // distance max parcourue � chq fois. on la met tt le tps � 1

	if (bouge < proba_mobilite){
		if (waypoint){//si on fait de la mobilit� waypoint
			//o� le noeud se dirige vers un point
			// si le noeud a atteint sa position, on lui trouve une nouvelle destination
			if ((node->posX == node->posX_waypoint) && (node->posY == node->posY_waypoint)){
				node->posX_waypoint = gener_alea(taille)+1;
				node->posY_waypoint = gener_alea(taille)+1;
			};

			//sinon, on le fait avancer vers cette destination
			if (node->posX < node->posX_waypoint) node->posX += 1;
			else if (node->posX > node->posX_waypoint) node->posX -= 1;

			if (node->posY < node->posY_waypoint) node->posY += 1;
			else if (node->posY > node->posY_waypoint) node->posY -= 1;
		}
		else{		
			//dist = gener_alea(vitesse_max)+1; //on met un "+1" pour ne pas avoir de 0
			//dist = gener_alea(vitesse_max); 

			//random walk
			//direction = gener_alea(8)+1;


			//on essaie de garder tjr la m�me direction
			if (gener_alea(100) < 67) direction = node->last_direction; // on garde la m�me direction ds 2/3 des cas
			else {
				direction = gener_alea(8)+1;
				node->last_direction = direction;
			};

			//compl�tement random
			//direction = gener_alea(8)+1;

			switch (direction){
				case 1:	//en haut � gauche
					//if ((node->posX - dist) < 1) node->posX = taille + (node->posX - dist);
					if ((node->posX - dist) < 1){
						node->posX = 1;
						node->last_direction = 2;
					}
					else node->posX = node->posX - dist;
					//if ((node->posY + dist) > taille) node->posY = (node->posY + dist) - taille;
					if ((node->posY + dist) > taille){
						node->posY = taille;
						node->last_direction = 2;
					}
					else node->posY = node->posY + dist;
					break;

				case 2:	//en haut
					if ((node->posY + dist) > taille){
						node->posY = taille;
						node->last_direction = 3;
					}
					else node->posY = node->posY + dist;
					break;

				case 3: //en haut � droite
					//if ((node->posX + dist) > taille) node->posX = (node->posX + dist) - taille;
					if ((node->posX + dist) > taille){
						node->posX = taille;
						node->last_direction = 4;
					}
					else node->posX = node->posX + dist;
					//if ((node->posY + dist) > taille) node->posY = (node->posY + dist) - taille;                                 
					if ((node->posY + dist) > taille){
						node->posY = taille;
						node->last_direction = 4;
					}
					else node->posY = node->posY + dist;
					break;

				case 4: //� droite
					//if ((node->posX + dist) > taille) node->posX = (node->posX + dist) - taille;
					if ((node->posX + dist) > taille){
						node->posX = taille;
						node->last_direction = 5;
					}
					else node->posX = node->posX + dist;
					break;

				case 5: //en bas � droite
					//if ((node->posX + dist) > taille) node->posX = (node->posX + dist) - taille;
					if ((node->posX + dist) > taille){
						node->posX = taille;
						node->last_direction = 6;
					}
					else node->posX = node->posX + dist;
					//if ((node->posY - dist) > taille) node->posY = (node->posX + dist) - taille;
					if ((node->posY - dist) > taille){
						node->posY = taille;
						node->last_direction = 6;
					}
					else node->posY = node->posY - dist;
					break;

				case 6: //en bas
					//if ((node->posY - dist) < 1) node->posY = taille + (node->posY - dist);                                 
					if ((node->posY - dist) < 1){
						node->posY = 1;
						node->last_direction = 7;
					}
					else node->posY = node->posY - dist;
					break;

				case 7: //en bas � gauche
					//if ((node->posX - dist) < 1) node->posX = taille + (node->posX - dist);                                 
					if ((node->posX - dist) < 1){
						node->posX = 1;                                 
						node->last_direction = 8;
					}
					else node->posX = node->posX - dist;
					//if ((node->posY - dist) < 1) node->posY = taille + (node->posY - dist);
					if ((node->posY - dist) < 1){
						node->posY = 1;
						node->last_direction = 8;
					}
					else node->posY = node->posY - dist;
					break;

				case 8: //� gauche
					//if ((node->posX - dist) < 1) node->posX = taille + (node->posX - dist);
					if ((node->posX - dist) < 1){ 
						node->posX = 1;
						node->last_direction = 1;
					}
					else node->posX = node->posX - dist;
					break;

				default:	//normalement, �a devrait pas arriver
					printf("bizarre �a\n");
					break;
			};
		};
		//else printf("ne bouge pas\n");
	};
};

void mobilite(noeud *topologie, int vitesse_noeud_max, int proba_mobilite, int taille, int portee, MYSQL *mysql, int nb_noeud, int waypoint){
	int i;
	char requete[80];

	//ajouter 1 � l'�ge de tous les noeuds
	sprintf(requete, "update routage set age=age+1, age_pdl=age_pdl+1 where id <= %d and id != id_noeud", nb_noeud);
	if (mysql_query(mysql,requete))
	{
		printf("impossible d'incr�menter l'�ge des rencontres\n");
		exit(1);
	};
	if (proba_mobilite){
		for (i=0; i<vitesse_noeud_max; i++){
			noeud *aux=topologie;
			while (aux){
				deplacer_noeud(aux, proba_mobilite, taille, waypoint);
				update_pos_noeud_BDD(aux, mysql);
				aux = aux->next;
			};

			//met � jour la position de tous les noeuds ds la table des positions des autres noeuds
			aux = topologie;
			while(aux){
				maj_tab_routage(aux, portee, mysql, nb_noeud);
				aux=aux->next;
			};
			//printf("mobilite apres %d iterations\n\n", i);
			//impr_topo(mysql, taille);
			//printf("\n\n");
		};
	};
	//impr_topo(mysql, taille, nb_noeud);
};
