--!strict
--[[
	NameParts.luau (SERVIDOR)
	Peças do gerador de nomes absurdos das poções procedurais.

	Nome = "{prefixo} {sujeito} {complemento}"  ->  "Poção do Pato Turbo"

	- sujeitos já vêm com o artigo ("do", "da") para o português ficar certo;
	- complementos são substantivos, assim não precisam concordar em gênero
	  ("do Pato Turbo", "da Vaca Turbo").

	O sujeito vem do traço de forma/tamanho; o complemento vem do traço de
	movimento ou visual. Se não houver traço, usa as listas "default".
	Adicione palavras à vontade, mas lembre: mudar estas listas muda o nome das
	poções procedurais que já existem (o efeito continua o mesmo).
]]

local NameParts = {}

NameParts.prefixes = { "Poção", "Poção", "Poção", "Elixir", "Xarope", "Tônico", "Suco" }

NameParts.defaultSubjects = {
	"do Galo",
	"da Vaca",
	"do Pato",
	"da Lhama",
	"do Pinguim",
	"da Galinha",
	"do Bode",
	"do Hamster",
	"da Capivara",
	"do Tatu",
	"da Girafa",
	"do Polvo",
}

NameParts.subjectsByTrait = {
	Giant = { "do Gigante", "do Elefante", "da Baleia", "do Dinossauro" },
	Mini = { "da Formiga", "do Anão de Jardim", "da Pulga", "do Grilo" },
	Frog = { "do Sapo", "da Perereca", "do Girino" },
	Ghost = { "do Fantasma", "da Assombração", "do Lençol" },
	Rock = { "da Pedra", "do Golem", "do Tijolo" },
	Cloud = { "da Nuvem", "do Algodão Doce", "do Travesseiro" },
	Metal = { "do Robô", "da Panela", "do Parafuso" },
	Pizza = { "da Pizza", "do Pizzaiolo", "da Calabresa" },
} :: { [string]: { string } }

NameParts.defaultComplements = { "de Pijama", "de Chapéu", "de Óculos", "de Patins", "de Sunga", "de Gravata" }

NameParts.complementsByTrait = {
	Fly = { "Foguete", "Jato", "Planador", "Pipa" },
	Floaty = { "Balão", "Astronauta", "Flutuante" },
	Bouncy = { "Pula-Pula", "Mola", "Saltitante", "Pogobol" },
	Speedy = { "Turbo", "Relâmpago", "Fórmula 1", "Expresso" },
	Slow = { "Lesma", "Preguiça", "Câmera Lenta", "Soneca" },
	Glow = { "Vaga-lume", "Lanterna", "Neon", "Abajur" },
	Fire = { "Vulcão", "Churrasco", "Brasa", "Pimentão" },
	Sparkle = { "Purpurina", "Glitter", "Estrelinha", "Brilhante" },
	Snow = { "Picolé", "Geladeira", "Sorvete", "Iglu" },
	Electric = { "Tomada", "Choquinho", "Pilha", "Faísca" },
	Bubbles = { "Sabonete", "Chiclete", "Espuma", "Banheira" },
	Rainbow = { "Unicórnio", "Arco-íris", "Discoteca", "Confete" },
	Cosmic = { "Galáxia", "Disco Voador", "Cometa", "Via Láctea" },
} :: { [string]: { string } }

return NameParts
