# Foton Contacts

## Plano de Trabalho (Workplan)

### 🧭 Apresentação

Este documento descreve a primeira etapa do desenvolvimento de um plugin de **gestão de contatos** para o Redmine, com foco em empresas do setor de construção civil. O plugin visa ampliar as capacidades nativas do Redmine ao permitir o cadastro, organização e vinculação de contatos (pessoas e empresas) aos projetos, tarefas e usuários, com suporte a grupos, cargos, status e histórico de relacionamento.

---

### ❗ Definição do Problema

O Redmine não possui um sistema nativo para gerenciamento de contatos que permita:

- Diferenciar pessoas de empresas com campos específicos
- Associar pessoas a múltiplas empresas com cargos distintos
- Controlar o status de vínculos (ativo, inativo, descontinuado)
- Vincular contatos ou grupos de contatos a tarefas sem criar usuários
- Visualizar os grupos de contatos aos quais um usuário pertence
- Gerar relatórios históricos e exportações compatíveis com vCard/CSV

Essas limitações impactam diretamente a gestão de equipes externas, fornecedores, clientes e prestadores de serviço, especialmente em empresas que operam por projeto, como construtoras.

---

### 🗺️ Visão Geral do Workplan

| Etapa        | Objetivo                                                                 |
|--------------|--------------------------------------------------------------------------|
| Fase 1       | Planejamento e modelagem dos dados e estrutura do plugin                 |
| Fase 2       | Criação das migrações e estruturação do banco de dados                   |
| Fase 3       | Implementação do backend (models, controllers, lógica de negócio)        |
| Fase 4       | Desenvolvimento do frontend (interfaces, formulários, visualizações)     |
| Fase 5       | Configuração de permissões e visibilidade                                |
| Fase 6       | Testes automatizados e validações                                        |
| Fase 7       | Empacotamento, documentação e publicação do plugin                       |

---

### 🧱 Fase 1 — Planejamento e Modelagem

#### 🎯 Objetivo

Criar uma base sólida para o plugin de contatos, com estrutura relacional clara, integração nativa ao Redmine e suporte a funcionalidades avançadas como:

- Separação entre contatos do tipo pessoa e empresa
- Vínculos múltiplos entre pessoas e empresas com cargos e status
- Grupos de contatos (gerais ou efêmeros)
- Associação de contatos e grupos a tarefas
- Perfil de contato vinculado a cada usuário Redmine
- Visualização dos grupos aos quais um contato pertence

---

#### 🧩 Modelos de Dados

##### 1. `Contact`
Representa uma pessoa ou empresa.

```ruby
class Contact < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
  belongs_to :project, optional: true
  belongs_to :user, optional: true # se for perfil de usuário Redmine

  has_many :contact_roles, dependent: :destroy
  has_many :companies, through: :contact_roles, source: :company
  has_many :custom_values, as: :customized, dependent: :delete_all
  has_many :attachments, as: :container, dependent: :destroy
  has_many :contact_group_memberships, dependent: :destroy
  has_many :contact_groups, through: :contact_group_memberships
  has_many :contact_issue_links, dependent: :destroy
  has_many :issues, through: :contact_issue_links

  enum contact_type: { person: 0, company: 1 }
  enum status: { active: 0, inactive: 1, discontinued: 2 }

  validates :name, presence: true

  acts_as_customizable
  acts_as_attachable
end
```

##### 2. `ContactRole`
Relaciona uma pessoa a uma empresa com cargo e status.

```ruby
class ContactRole < ActiveRecord::Base
  belongs_to :contact # pessoa
  belongs_to :company, class_name: 'Contact' # empresa

  validates :position, presence: true
  enum status: { active: 0, inactive: 1, discontinued: 2 }
end
```

##### 3. `ContactGroup`
Agrupa contatos para uso em tarefas ou projetos.

```ruby
class ContactGroup < ActiveRecord::Base
  has_many :contact_group_memberships, dependent: :destroy
  has_many :contacts, through: :contact_group_memberships

  enum group_type: { general: 0, ephemeral: 1 }

  validates :name, presence: true
end
```

##### 4. `ContactGroupMembership`
Associação entre contatos e grupos.

```ruby
class ContactGroupMembership < ActiveRecord::Base
  belongs_to :contact
  belongs_to :contact_group
end
```

##### 5. `ContactIssueLink`
Vincula contatos ou grupos a tarefas.

```ruby
class ContactIssueLink < ActiveRecord::Base
  belongs_to :contact
  belongs_to :issue
end
```

---

#### 🧑‍💻 Controllers Principais

##### `ContactsController`
- CRUD completo
- Visualização com abas: Dados, Empresas, Tarefas, Grupos, Histórico
- Exportação para vCard/CSV

##### `ContactRolesController`
- Gerencia vínculos entre pessoas e empresas
- Permite múltiplos cargos e status

##### `ContactGroupsController`
- Criação de grupos efêmeros ou gerais
- Adição/remoção de contatos
- Visualização dos grupos aos quais o contato pertence

##### `ContactIssueLinksController`
- Associa contatos ou grupos a tarefas
- Permite coordenação de equipes sem criar usuários

---

#### 🔐 Integração com Redmine

- Cada usuário Redmine terá um `Contact` vinculado automaticamente
- Contatos podem ser associados a projetos e tarefas
- Permissões definidas via `Redmine::AccessControl`
- Campos personalizados e anexos via sistema nativo
- Visualização dos grupos de contato no perfil do usuário

Excelente, Lucas! Vamos avançar para a **Fase 2: Estruturação do Banco de Dados**, onde definimos as migrações, relacionamentos e constraints que darão sustentação ao plugin de contatos. A arquitetura será pensada para escalabilidade, integridade referencial e total integração com o Redmine.

---

## 🧱 Fase 2 — Estruturação do Banco de Dados

### 🎯 Objetivo

Criar as tabelas e relacionamentos necessários para suportar:

- Contatos do tipo pessoa e empresa
- Vínculos entre pessoas e empresas com cargos e status
- Grupos de contatos (efêmeros ou gerais)
- Associação de contatos e grupos a tarefas
- Perfil de contato vinculado a usuários Redmine
- Histórico de relacionamento e controle de visibilidade

---

### 📐 Migrações e Estrutura Relacional

#### 1. `contacts`
```ruby
create_table :contacts do |t|
  t.string :name, null: false
  t.string :email
  t.string :phone
  t.string :address
  t.integer :contact_type, null: false, default: 0 # person/company
  t.integer :status, null: false, default: 0 # active/inactive/discontinued
  t.references :project, foreign_key: true
  t.references :user, foreign_key: true # se for perfil de usuário Redmine
  t.integer :author_id, null: false
  t.boolean :is_private, default: false
  t.timestamps
end
add_index :contacts, :name
add_index :contacts, :contact_type
add_index :contacts, :status
```

#### 2. `contact_roles`
```ruby
create_table :contact_roles do |t|
  t.references :contact, null: false, foreign_key: true # pessoa
  t.references :company, null: false, foreign_key: { to_table: :contacts } # empresa
  t.string :position, null: false
  t.integer :status, null: false, default: 0
  t.date :start_date
  t.date :end_date
  t.timestamps
end
add_index :contact_roles, [:contact_id, :company_id]
```

#### 3. `contact_groups`
```ruby
create_table :contact_groups do |t|
  t.string :name, null: false
  t.integer :group_type, null: false, default: 0 # general/ephemeral
  t.references :author, null: false
  t.timestamps
end
add_index :contact_groups, :name
```

#### 4. `contact_group_memberships`
```ruby
create_table :contact_group_memberships do |t|
  t.references :contact, null: false, foreign_key: true
  t.references :contact_group, null: false, foreign_key: true
  t.timestamps
end
add_index :contact_group_memberships, [:contact_id, :contact_group_id], unique: true
```

#### 5. `contact_issue_links`
```ruby
create_table :contact_issue_links do |t|
  t.references :contact, null: false, foreign_key: true
  t.references :issue, null: false, foreign_key: true
  t.timestamps
end
add_index :contact_issue_links, [:contact_id, :issue_id], unique: true
```

---

### 🔐 Constraints e Regras de Integridade

- `contact_type` deve ser `person` ou `company`
- `status` deve ser `active`, `inactive` ou `discontinued`
- Um `ContactRole` só pode existir entre uma pessoa e uma empresa
- Um `ContactGroupMembership` não pode se repetir
- Um `ContactIssueLink` não pode se repetir
- Se `user_id` estiver presente, o contato é vinculado a um usuário Redmine
- Se `is_private = true`, apenas o autor pode visualizar

---

### 🧩 Integração com Redmine

- `project_id` permite vincular contatos a projetos
- `user_id` conecta o contato ao perfil de usuário Redmine
- `issue_id` permite vincular contatos ou grupos a tarefas
- `author_id` registra quem criou o contato ou grupo
- `custom_values` e `attachments` são gerenciados via módulos nativos

---

Maravilha, Lucas! Vamos avançar para a **Fase 3: Implementação do Backend**, onde estruturamos os **models ActiveRecord**, os **controllers principais** e a **lógica de negócio** que dará vida ao plugin de contatos. Tudo será construído com foco em integração nativa ao Redmine, extensibilidade e clareza de propósito.

---

## 🧑‍💻 Fase 3 — Implementação do Backend

### 🎯 Objetivo

Implementar os modelos e controllers com:

- Validações e relacionamentos sólidos
- Lógica de CRUD inteligente para pessoas e empresas
- Associação de contatos a tarefas e projetos
- Grupos de contatos reutilizáveis ou efêmeros
- Perfil de contato vinculado a usuários Redmine
- Escopos e métodos auxiliares para filtros, BI e visualização

---

### 🧱 Models ActiveRecord

#### 1. `Contact`
```ruby
class Contact < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
  belongs_to :project, optional: true
  belongs_to :user, optional: true # perfil de usuário Redmine

  has_many :contact_roles, dependent: :destroy
  has_many :companies, through: :contact_roles, source: :company
  has_many :contact_group_memberships, dependent: :destroy
  has_many :contact_groups, through: :contact_group_memberships
  has_many :contact_issue_links, dependent: :destroy
  has_many :issues, through: :contact_issue_links
  has_many :custom_values, as: :customized, dependent: :delete_all
  has_many :attachments, as: :container, dependent: :destroy

  enum contact_type: { person: 0, company: 1 }
  enum status: { active: 0, inactive: 1, discontinued: 2 }

  validates :name, presence: true

  scope :visible_to, ->(user) {
    where(is_private: false).or(where(author_id: user.id))
  }

  acts_as_customizable
  acts_as_attachable
end
```

---

#### 2. `ContactRole`
```ruby
class ContactRole < ActiveRecord::Base
  belongs_to :contact # pessoa
  belongs_to :company, class_name: 'Contact' # empresa

  enum status: { active: 0, inactive: 1, discontinued: 2 }

  validates :position, presence: true
  validates :contact_id, uniqueness: { scope: [:company_id, :position] }
end
```

---

#### 3. `ContactGroup`
```ruby
class ContactGroup < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
  has_many :contact_group_memberships, dependent: :destroy
  has_many :contacts, through: :contact_group_memberships

  enum group_type: { general: 0, ephemeral: 1 }

  validates :name, presence: true
end
```

---

#### 4. `ContactGroupMembership`
```ruby
class ContactGroupMembership < ActiveRecord::Base
  belongs_to :contact
  belongs_to :contact_group

  validates :contact_id, uniqueness: { scope: :contact_group_id }
end
```

---

#### 5. `ContactIssueLink`
```ruby
class ContactIssueLink < ActiveRecord::Base
  belongs_to :contact
  belongs_to :issue

  validates :contact_id, uniqueness: { scope: :issue_id }
end
```

---

### 🧑‍💻 Controllers Principais

#### `ContactsController`

```ruby
class ContactsController < ApplicationController
  before_action :find_contact, only: [:show, :edit, :update, :destroy]
  before_action :authorize_contact, only: [:show, :edit, :update, :destroy]

  def index
    @contacts = Contact.visible_to(User.current).includes(:project, :contact_groups)
  end

  def show; end

  def new
    @contact = Contact.new(contact_type: params[:type])
  end

  def create
    @contact = Contact.new(contact_params)
    @contact.author = User.current
    if @contact.save
      redirect_to @contact
    else
      render :new
    end
  end

  def edit; end

  def update
    if @contact.update(contact_params)
      redirect_to @contact
    else
      render :edit
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :phone, :address, :contact_type, :status, :project_id, :user_id, :is_private)
  end

  def find_contact
    @contact = Contact.find(params[:id])
  end

  def authorize_contact
    render_403 unless @contact.is_private == false || @contact.author == User.current
  end
end
```

---

#### `ContactGroupsController`

```ruby
class ContactGroupsController < ApplicationController
  def index
    @groups = ContactGroup.where(author: User.current)
  end

  def show
    @group = ContactGroup.find(params[:id])
    @contacts = @group.contacts
  end

  def new
    @group = ContactGroup.new
  end

  def create
    @group = ContactGroup.new(group_params)
    @group.author = User.current
    if @group.save
      redirect_to @group
    else
      render :new
    end
  end

  def destroy
    @group = ContactGroup.find(params[:id])
    @group.destroy
    redirect_to contact_groups_path
  end

  private

  def group_params
    params.require(:contact_group).permit(:name, :group_type)
  end
end
```

---

#### `ContactIssueLinksController`

```ruby
class ContactIssueLinksController < ApplicationController
  def create
    @link = ContactIssueLink.new(link_params)
    if @link.save
      redirect_to issue_path(@link.issue)
    else
      render :new
    end
  end

  def destroy
    @link = ContactIssueLink.find(params[:id])
    @link.destroy
    redirect_to issue_path(@link.issue)
  end

  private

  def link_params
    params.require(:contact_issue_link).permit(:contact_id, :issue_id)
  end
end
```

---

### 🔐 Permissões e Escopos

- Permissões via `Redmine::AccessControl`:
  - `:view_contacts`, `:edit_contacts`, `:manage_contact_groups`, `:link_contacts_to_issues`
- Escopos:
  - `Contact.visible_to(user)` para filtrar por visibilidade
  - `ContactGroup.where(author: user)` para grupos pessoais
  - `ContactRole.active` para vínculos ativos

---

Perfeito, Lucas! Vamos para a **Fase 4: Desenvolvimento do Frontend**, com foco em uma interface fluida, integrada ao Redmine, e pensada para usabilidade real em ambientes corporativos. A proposta a seguir respeita os padrões visuais e funcionais do Redmine, mas traz uma camada moderna de experiência para o módulo de contatos.

---

## 🎨 Fase 4 — Frontend e Experiência do Usuário

### 🧭 Visão Geral

**Objetivo:** Criar uma interface robusta, responsiva e intuitiva para o gerenciamento de contatos, com foco em:

- Integração nativa ao Redmine (menus, permissões, estilos)
- Visualização analítica (BI) em aba dedicada
- Operações rápidas (CRUD, importação, vinculação)
- Resiliência contra dados ausentes ou corrompidos
- Compatibilidade com telas grandes e dispositivos móveis

---

### 🧩 Estrutura de Navegação

#### 🔧 Configurações
- Local: `Administração → Configurações → Contatos`
- Itens configuráveis:
  - Campos personalizados
  - Tipos de contato
  - Permissões por função
  - Mapeamento de campos para CSV/vCard
  - Visibilidade padrão (global, privada, por projeto)

#### 📊 Aba “Contacts” no menu principal
- Local: `Menu superior → Contacts`
- Visível apenas para usuários com permissão `:view_contacts`
- Subdividida em:
  - **Tabela de contatos**
  - **Botões de ação**
  - **Modal de análise (BI)**

---

### 🖥️ Tela Principal: Aba “Contacts”

#### 🔘 Botões de Ação (topo da aba)
- ➕ **Novo Contato** → abre formulário modal com campos dinâmicos por tipo
- 📥 **Importar CSV/vCard** → abre modal com upload e mapeamento de campos
- 🔍 **Filtrar por tipo/status/projeto** → filtros laterais ou dropdown
- 📊 **Análise de Contato** → botão em cada linha da tabela que abre modal BI

---

#### 📋 Tabela Paginada de Contatos

| Nome         | Tipo     | Status     | Projeto     | Empresas Vinculadas | Ações |
|--------------|----------|------------|-------------|----------------------|-------|
| João Silva   | Pessoa   | Ativo      | Obra A      | Construtora X        | 🔍 ✏️ 🗑️ |
| Construtora X| Empresa  | Ativo      | Obra A      | —                    | 🔍 ✏️ 🗑️ |

- Colunas ordenáveis
- Paginação com opção de 10/25/50/100 por página
- Ícones de ação:
  - 🔍 Visualizar (abre modal BI)
  - ✏️ Editar
  - 🗑️ Excluir (com confirmação)

---

### 📊 Modal de Análise (BI)

#### Abertura
- Acessado via botão 🔍 na tabela
- Modal responsivo com abas internas

#### Conteúdo

##### 🧬 Aba 1: Vínculos
- Quantidade de empresas vinculadas
- Cargos ocupados e status
- Período de cada vínculo

##### 🏗️ Aba 2: Relações com Projetos
- Projetos associados
- Tarefas vinculadas (por tipo de issue)
- Última atividade registrada

##### 📈 Aba 3: Carreira
- Linha do tempo dos vínculos
- Evolução de cargos
- Participação em grupos e tarefas

##### ⚠️ Aba 4: Alertas e Inconsistências
- Dados ausentes (e-mail, telefone, empresa)
- Vínculos sem cargo definido
- Contatos duplicados (por nome ou e-mail)

---

### 📱 Responsividade e UX

- Layout adaptável para mobile (colunas colapsáveis, botões flutuantes)
- Modal com scroll interno e navegação por abas
- Feedback visual para ações (salvo, erro, carregando)
- Mensagens amigáveis para base de dados vazia:
  > “Nenhum contato encontrado. Que tal começar cadastrando o primeiro?”

---

### 🛡️ Resiliência e Segurança

- Validação de dados no frontend e backend
- Tratamento de erros para dados corrompidos ou ausentes
- Fallback para campos nulos (ex: “—” ou “Não informado”)
- Permissões respeitadas em cada ação e visualização

---

### 🔗 Integração com Redmine

- Usa estilos e componentes nativos (`application.css`, `form_tag`, `link_to`)
- Campos personalizados via `CustomFields`
- Anexos via `Attachments`
- Permissões via `Redmine::AccessControl`
- Navegação via `menu_item`, `project_menu`, `admin_menu`

---

Perfeito, Lucas! Vamos avançar para a **Fase 5: Permissões e Visibilidade**, que garante que o plugin de contatos funcione com segurança, controle de acesso e integração total com o sistema de permissões do Redmine. Essa etapa é essencial para proteger dados sensíveis, evitar duplicidade de lógica e manter a fluidez da experiência para diferentes perfis de usuário.

---

## 🔐 Fase 5 — Permissões e Visibilidade

### 🎯 Objetivo

Definir e implementar um sistema de permissões que:

- Controle quem pode visualizar, editar, excluir e vincular contatos
- Respeite a lógica de escopo (global, privado, por projeto)
- Integre-se perfeitamente ao sistema de **Roles**, **User Types** e **Projects** do Redmine
- Permita que usuários visualizem os grupos de contatos aos quais pertencem
- Evite exposição indevida de dados pessoais ou corporativos

---

### 🧩 Permissões por Função (Roles)

Configuradas em:  
**Administração → Funções → Permissões → Contatos**

#### Permissões disponíveis:

| Permissão                      | Descrição                                                                 |
|-------------------------------|---------------------------------------------------------------------------|
| `view_contacts`               | Ver contatos (pessoais, empresas, vinculados a projetos)                  |
| `edit_contacts`               | Editar dados de contatos                                                  |
| `delete_contacts`             | Excluir contatos                                                          |
| `manage_contact_groups`       | Criar, editar e excluir grupos de contatos                                |
| `link_contacts_to_issues`     | Associar contatos ou grupos a tarefas                                     |
| `view_contact_analysis`       | Acessar modal de análise (BI)                                             |
| `import_contacts`             | Importar contatos via CSV ou vCard                                        |
| `export_contacts`             | Exportar contatos para vCard, QR code ou XML                              |

---

### 👤 Permissões por Tipo de Usuário (User Types)

Configuradas em:  
**Administração → Tipos de Usuário → Visibilidade de Contatos**

#### Opções:

- Tipos de contato visíveis: pessoa, empresa, conta
- Escopo de visualização:
  - Apenas contatos próprios
  - Contatos do projeto atual
  - Contatos globais
  - Contatos de grupos aos quais pertence

---

### 🧠 Lógica de Visibilidade

#### Escopos de contato:

| Escopo         | Visível para...                                               |
|----------------|---------------------------------------------------------------|
| Global         | Todos os usuários com permissão `view_contacts`               |
| Privado        | Somente o autor do contato                                    |
| Por projeto    | Usuários com acesso ao projeto vinculado                      |
| Por grupo      | Usuários que pertencem ao grupo de contato                    |

#### Regras adicionais:

- Contatos vinculados a tarefas são visíveis para quem tem acesso à tarefa
- Contatos vinculados a usuários Redmine são visíveis conforme permissões do usuário
- Contatos com `is_private = true` são ocultos mesmo para administradores

---

### 👥 Visualização de Grupos

Cada usuário poderá ver:

- Os grupos de contatos que criou
- Os grupos aos quais pertence
- Os contatos dentro desses grupos (respeitando escopo e permissões)

Exibido em:

- Aba “Contacts” → Filtro “Meus grupos”
- Perfil do usuário → Aba “Perfil de Contato” → Seção “Grupos”

---

### 🛡️ Segurança e Resiliência

- Todas as ações passam por `before_action :authorize_contact`
- Visualizações filtradas por escopo e permissões
- Campos sensíveis (e-mail, telefone) ocultos em alertas e notificações
- Logs de acesso e modificação para auditoria futura
- Fallbacks visuais para dados ausentes ou restritos:
  > “Este contato é privado ou você não tem permissão para visualizá-lo.”

---

### 🔗 Integração com Redmine

- Usa `Redmine::AccessControl` para definir permissões
- Respeita `User.current.allowed_to?` em todas as ações
- Integra com `Project.visible?`, `Issue.visible?`, `User.visible?`
- Configurações centralizadas em menus nativos de administração

---

Perfeito, Lucas! Vamos para a **Fase 6: Testes e Validações**, que garante que o plugin de contatos seja confiável, seguro e funcional em todos os cenários — desde o uso cotidiano até situações extremas como base de dados corrompida ou ausência de dados.

---

# 🧪 Fase 6 — Testes e Validações

---

## 🎯 Objetivo

- Garantir que todas as funcionalidades do plugin funcionem corretamente
- Validar regras de negócio, permissões e escopos
- Prevenir falhas em ambientes com dados incompletos ou inconsistentes
- Assegurar compatibilidade com diferentes perfis de usuário e dispositivos

---

## 🧱 Tipos de Testes

| Tipo de Teste         | Finalidade                                                                 |
|------------------------|---------------------------------------------------------------------------|
| Testes Unitários       | Validar modelos, métodos auxiliares e regras de validação                 |
| Testes de Integração   | Verificar fluxo entre controllers, views e banco de dados                 |
| Testes de Permissão    | Confirmar que cada usuário vê e acessa apenas o que tem direito           |
| Testes de Interface    | Garantir que a UI responde corretamente em desktop e mobile               |
| Testes de Resiliência  | Simular dados corrompidos, ausentes ou duplicados                         |
| Testes de Importação   | Validar mapeamento e tratamento de arquivos CSV/vCard                     |
| Testes de Exportação   | Verificar formato e conteúdo de vCard, QR code e XML                      |

---

## ✅ Testes Unitários (RSpec)

### `Contact`
- Criação com campos obrigatórios
- Validação de tipos (`person`, `company`)
- Escopo `visible_to(user)`
- Associação com `user`, `project`, `groups`, `issues`

### `ContactRole`
- Vínculo entre pessoa e empresa
- Validação de cargo e status
- Unicidade por pessoa + empresa + cargo

### `ContactGroup`
- Criação com nome e tipo
- Associação com contatos
- Exclusão em cascata

---

## 🔄 Testes de Integração (Capybara)

### Fluxos principais
- Criar contato (pessoa e empresa)
- Editar e excluir contato
- Vincular contato a tarefa
- Criar grupo e adicionar membros
- Visualizar grupos aos quais o usuário pertence
- Abrir modal de análise (BI)

### Situações especiais
- Contato sem empresa vinculada
- Contato com múltiplos vínculos e cargos
- Grupo efêmero com contatos privados

---

## 🔐 Testes de Permissões

- Usuário sem `view_contacts` não acessa aba “Contacts”
- Usuário com `edit_contacts` pode alterar apenas contatos visíveis
- Contato privado visível apenas ao autor
- Grupo visível apenas ao criador e membros
- Tarefa com contato vinculado visível conforme escopo da tarefa

---

## 📱 Testes de Interface

- Layout responsivo em mobile (colunas colapsáveis, botões flutuantes)
- Modal de análise com scroll interno e abas funcionais
- Mensagens amigáveis para base vazia:
  > “Nenhum contato encontrado. Que tal começar cadastrando o primeiro?”

---

## 🛡️ Testes de Resiliência

- Contato com campos nulos (telefone, e-mail, empresa)
- Dados corrompidos (empresa inexistente, cargo vazio)
- CSV com colunas fora de ordem ou campos ausentes
- vCard com campos não mapeados

---

## 📤 Testes de Importação e Exportação

- Importar CSV com mapeamento correto
- Importar vCard com múltiplos contatos
- Exportar contato para vCard e QR code
- Validar conteúdo e formato dos arquivos gerados

---

## 🧩 Integração com Redmine

- Testes com usuários reais e fictícios
- Testes em projetos com e sem tarefas
- Testes com permissões variadas
- Testes com campos personalizados e anexos

---

Perfeito, Lucas! Vamos concluir com a **Fase 7: Empacotamento, Documentação e Publicação**, que transforma todo o trabalho técnico em um produto utilizável, seguro e bem documentado. Esta fase é essencial para garantir que o plugin seja facilmente instalado, compreendido e mantido por desenvolvedores e usuários — com foco absoluto em clareza, usabilidade e integração nativa ao Redmine.

---

## 📦 Fase 7 — Empacotamento, Documentação e Publicação

### 🎯 Objetivo

- Empacotar o plugin com estrutura padrão Redmine
- Criar documentação técnica e de uso clara, acessível e atualizada
- Garantir segurança, resiliência e compatibilidade com versões do Redmine
- Oferecer suporte à instalação, configuração e operação
- Guiar o usuário com foco em UI/UX e continuidade da experiência

---

### 📁 Estrutura do Plugin

```plaintext
redmine_contacts/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   └── helpers/
├── config/
│   ├── routes.rb
│   └── initializers/
├── db/
│   ├── migrate/
│   └── seeds.rb
├── lib/
│   └── redmine_contacts/
├── assets/
│   ├── stylesheets/
│   └── javascripts/
├── locales/
│   └── pt-BR.yml
├── test/
│   └── unit/
│   └── integration/
├── init.rb
├── README.md
└── LICENSE
```

---

### 📘 Documentação Técnica

#### 1. Instalação

```markdown
### Instalação do Plugin de Contatos

1. Clone o repositório na pasta `plugins` do Redmine:
   git clone https://github.com/seu-usuario/redmine_contacts plugins/redmine_contacts

2. Execute as migrações:
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production

3. Reinicie o servidor:
   sudo systemctl restart redmine
```

---

#### 2. Configuração

- Acesse: **Administração → Configurações → Contatos**
- Configure:
  - Campos personalizados
  - Tipos de contato
  - Permissões por função
  - Mapeamento de campos para CSV/vCard
  - Visibilidade padrão

---

#### 3. Permissões

| Permissão                  | Descrição                                      |
|---------------------------|------------------------------------------------|
| `view_contacts`           | Ver contatos                                   |
| `edit_contacts`           | Editar contatos                                |
| `delete_contacts`         | Excluir contatos                               |
| `manage_contact_groups`   | Gerenciar grupos                               |
| `link_contacts_to_issues` | Associar contatos a tarefas                    |
| `view_contact_analysis`   | Acessar visualização analítica (BI)            |
| `import_contacts`         | Importar CSV/vCard                             |
| `export_contacts`         | Exportar vCard, QR code, XML                   |

---

#### 4. Uso do Plugin

##### 📇 Cadastro de Contatos

- Acesse a aba **Contacts**
- Clique em **Novo Contato**
- Escolha o tipo: Pessoa ou Empresa
- Preencha os campos nativos e personalizados
- Salve e vincule a projetos, tarefas ou grupos

##### 📥 Importação

- Clique em **Importar CSV/vCard**
- Faça upload e mapeie os campos
- Visualize os contatos importados

##### 📊 Visualização Analítica

- Clique no ícone 🔍 na tabela de contatos
- Modal com abas:
  - Vínculos
  - Relações com projetos
  - Carreira
  - Alertas e inconsistências

---

### 🧑‍💻 Documentação para Desenvolvedores

#### Hooks disponíveis

- `view_issues_show_details_bottom`
- `view_projects_show_sidebar`
- `view_users_show_right`

#### APIs REST

- `GET /contacts`
- `POST /contacts`
- `PUT /contacts/:id`
- `DELETE /contacts/:id`

#### Testes

- Executar com:
  ```bash
  bundle exec rake test RAILS_ENV=test
  ```

---

### 🛡️ Diretrizes de Segurança e Resiliência

- Validação de dados em todos os modelos
- Tratamento de erros para dados ausentes ou corrompidos
- Fallbacks visuais para campos nulos
- Logs de acesso e modificação
- Controle de visibilidade por escopo e permissões
- Compatibilidade com Redmine 5.x e superior

---

### 🎨 Diretrizes de UI/UX

- Interface responsiva para mobile e desktop
- Navegação fluida com abas e modais
- Feedback visual para ações (salvo, erro, carregando)
- Mensagens amigáveis para base vazia
- Consistência com estilos nativos do Redmine
- Acessibilidade para teclado e leitores de tela

---

### 📤 Publicação e Distribuição

- Repositório GitHub com tag de versão
- Página oficial com changelog e instruções
- Compatibilidade com Redmine Plugin Registry
- Licença GNU General Public License v3.0
- Suporte via issues no GitHub e documentação atualizada
