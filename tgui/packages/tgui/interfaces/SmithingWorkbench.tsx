import { Box, NoticeBox, Section, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Recipe = {
  name: string;
  materials: { name: string; amount: number }[];
  strikes: number;
};

type Data = {
  recipes: Recipe[];
  loaded: Record<string, number>;
  selected_pattern: string | null;
  assembly_strikes: number;
  finished_item: string | null;
};

export const SmithingWorkbench = () => {
  const { data } = useBackend<Data>();
  const { recipes, loaded, selected_pattern, assembly_strikes, finished_item } =
    data;

  return (
    <Window width={520} height={540} title="Smithing Workbench">
      <Window.Content scrollable>
        <NoticeBox info>
          Load quenched parts and wood, then use a forging hammer on the
          workbench to assemble a pattern.
        </NoticeBox>
        {!!finished_item && (
          <NoticeBox success>
            {finished_item} is ready. Click the workbench with an empty hand to
            collect it.
          </NoticeBox>
        )}
        <Section title="Assembly Patterns">
          <Table>
            <Table.Row bold>
              <Table.Cell>Item</Table.Cell>
              <Table.Cell>Materials (loaded / needed)</Table.Cell>
              <Table.Cell textAlign="right">Hammer strikes</Table.Cell>
            </Table.Row>
            {recipes.map((recipe) => (
              <Table.Row key={recipe.name}>
                <Table.Cell py={0.5}>{recipe.name}</Table.Cell>
                <Table.Cell>
                  {recipe.materials.map(({ name, amount }) => {
                    const count = loaded[name] ?? 0;
                    return (
                      <Box key={name} color={count >= amount ? 'good' : 'label'}>
                        {count} / {amount} {name}
                      </Box>
                    );
                  })}
                </Table.Cell>
                <Table.Cell textAlign="right">
                  {selected_pattern === recipe.name
                    ? `${assembly_strikes} / ${recipe.strikes}`
                    : recipe.strikes}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
