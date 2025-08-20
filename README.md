# Atividade-5-Pizzaria-Automatizada

- Crie o código em seu github
- Documente em inglês o código
- Apresente para a turma sua proposta

Objetivo:
O projeto da pizzaria precisa ser instalado de maneira dinâmica em qualquer servidor e deve estar sempre atualizado com o repositório do github.
Poste o link pro arquivo nesta tarefa

- Crie um script de deploy que instala todos os requisitos [ docker.io e outros pacotes necessários ]
- O script deve dar um git pull de seu repositório dentro da máquina em que é executado
- O script deve chamar o docker compose e subir a pizzaria
- O sistema deve ser acessivel na porta usada pela plataforma
- O script deve se instalar na crontab e rodar a cada 5 minutos
- Garanta que a imagem sempre sera reconstruída 

Dica: voce pode usar git hooks para agilizar o processo
Dica 2: você pode checar quais arquivos mudaram e sódisparar a montagem da imagem se houverem mudanças :) 
O sistema deve se auto atualizar quando fizer um push no repositório.
