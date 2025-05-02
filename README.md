# App-Bebidas
Projeto baseado em estoque de bebidas, feito para gerenciar as bebidas usando programa Dart/Flutter, banco de dados não relacional (Realtime database)

## Requisitos Funcionais

. Autenticação de usuários
    Permitir que usuários (funcionários/administradores) façam login usando suas contas Google (já que o Google Sign-In está configurado!).
    Verificar se um usuário autenticado é um funcionário ou um administrador para conceder acesso apropriado (suas regras de segurança já fazem isso!).
. Gerenciamento de bebidas
    Visualizar uma lista de todas as bebidas disponíveis (para usuários autenticados).
    Adicionar novas bebidas (apenas para funcionários/administradores).
    Editar detalhes de bebidas existentes (apenas para funcionários/administradores).
    Excluir bebidas (apenas para funcionários/administradores).
. Gerenciamento de estoques
    Visualizar os níveis de estoque atuais para cada bebida (apenas para funcionários/administradores, conforme suas regras).
    Atualizar a quantidade de estoque para uma bebida (apenas para funcionários/administradores).
    Validar que a quantidade de estoque seja um número positivo ou zero (suas regras de validação no nó estoques/$bebidaId/quantidade já ajudam nisso!).
. Gerenciamento de funcionários
    Visualizar a lista de funcionários (apenas para administradores, conforme suas regras).
    Adicionar novos funcionários, associando-os a uma conta de usuário autenticada (apenas para administradores).
    Editar informações de funcionários (apenas para administradores).
    Remover funcionários (apenas para administradores).
    Validar dados essenciais de funcionários como o CPF (suas regras de validação no nó funcionarios/$funcionarioId já ajudam nisso!).
. Gerenciamento de Clientes
    Visualizar a lista de clientes (apenas para funcionários/administradores, conforme suas regras).
    Adicionar novos clientes (apenas para funcionários/administradores).
    Editar informações de clientes (apenas para funcionários/administradores).
    Excluir clientes (apenas para funcionários/administradores).
    Validar dados essenciais de clientes como o CPF (suas regras de validação no nó clientes/$clienteId já ajudam nisso!).
. Flitro de busca para bebidas
. Notificações (Cloud Functions)

## Requisitos não funcionais

  . Segurança:
      Garantir que as regras de segurança do Realtime Database sejam a única forma de controlar o acesso aos dados, impedindo leitura/escrita não autorizada (suas regras atuais já abordam isso, mas revise se cobrem todos os cenários!).
      Proteger as contas de usuário usando o Firebase Authentication.
      Garantir que dados sensíveis (como CPF, se armazenados) sejam manuseados com cuidado.
  . Performance:
      O aplicativo deve carregar as listas de bebidas, estoque, funcionários e clientes rapidamente, mesmo com um grande volume de dados. A estrutura dos dados no RTDB impacta diretamente a performance.
      Operações de leitura e escrita devem ser ágeis.
  . Escalabilidade:
      O aplicativo deve ser capaz de lidar com um número crescente de bebidas, itens de estoque, funcionários e clientes ao longo do tempo. O Firebase RTDB é projetado para escalar automaticamente.
  . Usabilidade:
      A interface do usuário (seja web ou mobile) deve ser intuitiva e fácil para funcionários e administradores realizarem suas tarefas de gerenciamento.
  . Confiabilidade:
      Os dados no Realtime Database devem ser consistentes e não devem ser perdidos. O Firebase gerencia a persistência e sincronização dos dados.
      O aplicativo deve estar disponível quando necessário. O Firebase oferece alta disponibilidade.
  . Tempo Real:
      Alterações nos dados (como atualização de estoque) devem ser refletidas quase instantaneamente para outros usuários visualizando esses dados (uma característica forte do RTDB!).
  . Custo:
      Como você está no plano Spark, um requisito não funcional importante é garantir que o uso dos serviços do Firebase (principalmente Realtime Database Reads/Writes/Storage e Authentication) permaneça dentro dos limites no-cost do Spark para evitar interrupções ou a necessidade de upgrade imediato para o plano Blaze.
. Manutenibilidade:
      O código-fonte do seu aplicativo deve ser organizado e fácil de manter, depurar e atualizar.
      As regras de segurança devem ser claras e fáceis de entender/modificar.
