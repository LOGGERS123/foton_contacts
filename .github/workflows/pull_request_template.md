# 📦 Descrição da Pull Request

> Explique de forma clara e objetiva o que esta PR faz.  
> Evite jargões técnicos desnecessários e foque no valor da mudança.

- Tipo de contato: Pessoa ou Empresa
- Nova funcionalidade, correção ou melhoria?
- Impacto esperado no usuário final

---

## ✅ Checklist de Verificação

- [ ] A funcionalidade está integrada ao Redmine sem duplicidade
- [ ] A UI/UX está fluida, responsiva e consistente com o Redmine
- [ ] Os dados são validados corretamente no frontend e backend
- [ ] Os testes unitários e de integração foram executados com sucesso
- [ ] A documentação foi atualizada (README, comentários, changelog)
- [ ] A permissão necessária foi definida e testada
- [ ] A funcionalidade lida bem com base de dados vazia ou corrompida

---

## 🧪 Como Testar

> Descreva os passos para testar esta PR localmente.

1. Acesse a aba “Contacts”
2. Clique em “Novo Contato” e selecione o tipo
3. Preencha os campos e salve
4. Verifique se o contato aparece na tabela
5. Clique no botão 🔍 para abrir o modal analítico
6. Teste em tela grande e mobile

---

## 📎 Referências Relacionadas

> Se aplicável, adicione links para issues, discussões ou documentação.

- Issue #123
- Discussão sobre vinculação múltipla
- [Design proposto para modal BI](https://figma.com/projeto-contatos-redmine)

---

## 🧠 Observações Finais

> Algum ponto técnico relevante, limitação conhecida ou sugestão de melhoria futura?

- Esta PR prepara a base para vinculação de contatos a múltiplas tarefas
- A lógica de fallback para dados nulos foi reforçada
