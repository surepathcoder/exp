"""create_projects_and_migrate_data

Revision ID: a28d613ba812
Revises: 9ee8c4416213
Create Date: 2026-05-25 14:10:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'a28d613ba812'
down_revision: Union[str, None] = '9ee8c4416213'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Get bind and inspect database state
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = inspector.get_table_names()
    
    # 1. Create projectstatusenum and projects table only if projects doesn't exist
    if 'projects' not in tables:
        op.execute("DROP TYPE IF EXISTS projectstatusenum CASCADE")
        project_status_enum = sa.Enum('upcoming', 'active', 'completed', 'expired', 'cancelled', name='projectstatusenum')
        project_status_enum.create(bind, checkfirst=True)

        # Get currencyenum Type (already exists)
        currency_enum = postgresql.ENUM('USD', 'TZS', 'KES', name='currencyenum', create_type=False)

        # Create projects table
        op.create_table(
            'projects',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('name', sa.String(), nullable=False),
            sa.Column('description', sa.String(), nullable=True),
            sa.Column('budget', sa.Numeric(precision=18, scale=2), nullable=True),
            sa.Column('currency', currency_enum, nullable=False, server_default='USD'),
            sa.Column('status', project_status_enum, nullable=False, server_default='active'),
            sa.Column('start_date', sa.DateTime(), nullable=True),
            sa.Column('end_date', sa.DateTime(), nullable=True),
            sa.Column('user_id', sa.Integer(), nullable=True),
            sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_projects_id'), 'projects', ['id'], unique=False)

    # 2. Add project_id columns as FK to expenses and incomes if not present
    columns_expenses = [c['name'] for c in inspector.get_columns('expenses')]
    if 'project_id' not in columns_expenses:
        op.add_column('expenses', sa.Column('project_id', sa.Integer(), nullable=True))
        op.create_foreign_key('fk_expenses_projects', 'expenses', 'projects', ['project_id'], ['id'])
        
    columns_incomes = [c['name'] for c in inspector.get_columns('incomes')]
    if 'project_id' not in columns_incomes:
        op.add_column('incomes', sa.Column('project_id', sa.Integer(), nullable=True))
        op.create_foreign_key('fk_incomes_projects', 'incomes', 'projects', ['project_id'], ['id'])

    # 3. Data Migration: Extract unique project names from expenses and insert into projects
    if 'project' in columns_expenses:
        # Get all unique projects from expenses
        result = bind.execute(sa.text("SELECT DISTINCT project FROM expenses WHERE project IS NOT NULL"))
        projects_list = [row[0] for row in result if row[0]]
        
        # Insert unique project names if they don't already exist in projects table
        for project_name in projects_list:
            existing = bind.execute(
                sa.text("SELECT id FROM projects WHERE name = :name"),
                {"name": project_name}
            ).first()
            if not existing:
                bind.execute(
                    sa.text("INSERT INTO projects (name, status, currency, created_at) VALUES (:name, 'active', 'USD', now())"),
                    {"name": project_name}
                )

        # Map project names to project IDs in expenses
        bind.execute(
            sa.text("""
                UPDATE expenses 
                SET project_id = (SELECT id FROM projects WHERE projects.name = expenses.project LIMIT 1)
                WHERE project IS NOT NULL
            """)
        )

        # 4. Drop legacy project string column from expenses
        op.drop_column('expenses', 'project')


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns_expenses = [c['name'] for c in inspector.get_columns('expenses')]
    
    # 1. Add back project string column to expenses if not present
    if 'project' not in columns_expenses:
        op.add_column('expenses', sa.Column('project', sa.String(), nullable=True))

    # 2. Migrate names back to string column in expenses
    bind.execute(
        sa.text("""
            UPDATE expenses 
            SET project = (SELECT name FROM projects WHERE projects.id = expenses.project_id)
            WHERE project_id IS NOT NULL
        """)
    )

    # 3. Drop foreign keys and columns
    op.drop_constraint('fk_incomes_projects', 'incomes', type_='foreignkey')
    op.drop_column('incomes', 'project_id')
    
    op.drop_constraint('fk_expenses_projects', 'expenses', type_='foreignkey')
    op.drop_column('expenses', 'project_id')

    # 4. Drop projects table
    op.drop_index(op.f('ix_projects_id'), table_name='projects')
    op.drop_table('projects')

    # 5. Drop projectstatusenum type
    op.execute("DROP TYPE IF EXISTS projectstatusenum CASCADE")
